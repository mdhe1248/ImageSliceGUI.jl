function imslice_gui_layout(img; lbl = "imsliceGUI", clim = (0, maximum(img)), xrot_init = 0, yrot_init = 0, zrot_init = 0) 
  scalefun = scaleminmax(clim...)
  img = scalefun.(img)

  #### Window
  win = GtkWindow(lbl)

  ## Sliders
  sl_xrot = slider(0:360)
  sl_yrot = slider(0:360)
  sl_zrot = slider(0:360)
  frng = ceil(Int, sqrt(sum([size(img).^2...]))) #Frame range
  sl_fr = slider(-frng:frng)

  #### Canvas
  c = canvas(UserUnit)

  #### Draw functions
  tform = Vector{AffineMap{RotXYZ{Float64}, StaticArraysCore.SVector{3, Float64}}}(undef, 1)
  sl_xrot[] = xrot_init
  sl_yrot[] = yrot_init
  sl_zrot[] = zrot_init
  sl_fr[] = 1 #Depending on the frame range, this value may change in the below.
  action = map(sl_xrot, sl_yrot, sl_zrot, sl_fr) do xrot, yrot, zrot, fr
    tfm = recenter(RotXYZ(π/180*xrot[],π/180*yrot[],π/180*last(zrot[])), Images.center(img))
    imgw = warpedview(img, tfm, 0)
    #Frame range adjustment
    if fr[] > last(imgw.indices[3])
      sl_fr[] = min(fr[], last(imgw.indices[3]))
    elseif fr[] <  first(imgw.indices[3])
      sl_fr[] = max(fr[], first(imgw.indices[3]))
    end
    imgwview = parent(imgw[:,:, sl_fr[]])
    draw(c, Observable(imgwview)) do cnvs, img
       ctx = getgc(cnvs)
       copy!(ctx, img)
    end
  tform[1] = tfm
  end

  #### text box
  xrot_tb = textbox(Int; observable= observable(sl_xrot))
  yrot_tb = textbox(Int; observable= observable(sl_yrot))
  zrot_tb = textbox(Int; observable= observable(sl_zrot))
  fr_tb = textbox(Int; observable= observable(sl_fr))
  set_gtk_property!(xrot_tb, :width_chars,4)
  set_gtk_property!(yrot_tb, :width_chars,4)
  set_gtk_property!(zrot_tb, :width_chars,4)
  set_gtk_property!(fr_tb, :width_chars,4)

  #### Buttons
  ## xrotation buttons
  xrot_up_but = button("up")
  action = map(xrot_up_but) do val
    sl_xrot[] += 1
  end
  xrot_dn_but = button("dn")
  action = map(xrot_dn_but) do val
    sl_xrot[] -= 1
  end

  ## yrotation buttons
  yrot_up_but = button("up")
  action = map(yrot_up_but) do val
    sl_yrot[] += 1
  end
  yrot_dn_but = button("dn")
  action = map(yrot_dn_but) do val
    sl_yrot[] -= 1
  end

  ## zrotation buttons
  zrot_up_but = button("up")
  action = map(zrot_up_but) do val
    sl_zrot[] += 1
  end
  zrot_dn_but = button("dn")
  action = map(zrot_dn_but) do val
    sl_zrot[] -= 1
  end

  ## frame buttons
  fr_up_but = button("up")
  action = map(fr_up_but) do val
    sl_fr[] += 1
  end
  fr_dn_but = button("dn")
  action = map(fr_dn_but) do val
    sl_fr[] -= 1
  end

  ## Layout
  xrot_bxv = GtkBox(:v)
  push!(xrot_bxv, xrot_up_but)
  push!(xrot_bxv, xrot_dn_but)
  yrot_bxv = GtkBox(:v)
  push!(yrot_bxv, yrot_up_but)
  push!(yrot_bxv, yrot_dn_but)
  zrot_bxv = GtkBox(:v)
  push!(zrot_bxv, zrot_up_but)
  push!(zrot_bxv, zrot_dn_but)
  fr_bxv = GtkBox(:v)
  push!(fr_bxv, fr_up_but)
  push!(fr_bxv, fr_dn_but)
  return(win, xrot_tb, xrot_bxv, yrot_tb, yrot_bxv, zrot_tb, zrot_bxv, fr_tb, fr_bxv, sl_xrot, sl_yrot, sl_zrot, sl_fr, c)
end

"""
kwargs:
`lbl` is window name. 
`clim` is contrast limit. .
`xrot_init`, `yrot_init`, `zrot_init` in degree for the initial rotations

default: 
lbl = "imsliceGUI"
clim = (0, maximum(img))
xrot_init = yrot_init = zrot_init = 0

tform = imslice_gui(img)
The output is transform (rotation).
"""
function imslice_gui(img; lbl = "imsliceGUI", clim = (0, maximum(img)), xrot_init = 0, yrot_init = 0, zrot_init = 0)
  win, xrot_tb, xrot_bxv, yrot_tb, yrot_bxv, zrot_tb, zrot_bxv, fr_tb, fr_bxv, sl_xrot, sl_yrot, sl_zrot, sl_fr, c = imslice_gui_layout(img; lbl = lbl, clim = clim, xrot_init = xrot_init, yrot_init = yrot_init, zrot_init = zrot_init)
  ## No text box and botton for moving - fixed pair
  g = GtkGrid()
  g[1,1] = widget(xrot_tb)
  g[2,1] = xrot_bxv
  g[3,1] = widget(yrot_tb)
  g[4,1] = yrot_bxv
  g[5,1] = widget(zrot_tb)
  g[6,1] = zrot_bxv
  g[7,1] = widget(fr_tb)
  g[8,1] = fr_bxv
  g[1:2,2] = widget(sl_xrot)
  g[3:4,2] = widget(sl_yrot)
  g[5:6,2] = widget(sl_zrot)
  g[7:8,2] = widget(sl_fr)
  g[1:8,3] = widget(c)
  push!(win, g)

  return(tform)
end

# FIXME incorporate struct variable
mutable struct TransformPair
  tform::AffineMap
  z_index::Int
  section_index::Int
end

"""
Sometimes, one prepares a series of brain sections on a slideglass and tries to register them to allen brain atlas.
In this case, providing `sectionindices` argument would help. From the viewer, after loading brain atlas, find the region that matches well with one of your images. 
(For this you may need to visualize your images using a separate viewer (e.g. ImageView).)
Then, update the index of your image in the text box and click Pair. 

The outputs are (1) the transform (rotation) matrix of the current view, (2) a vector containing transform matrices for each paired section, and (3) Pairs of reference z-index and sectionID.

example:
current_tform, tforms, ps = imslice_gui(img, sectionindices = 1:51)

Note, `sectionindices` should be a vector/range of continuous integers, starting from 1.
"""
function imslice_gui(img, sectionindices::AbstractVector; lbl = "imsliceGUI", clim = (0, maximum(img)), xrot_init = 0, yrot_init = 0, zrot_init = 0)
  win, xrot_tb, xrot_bxv, yrot_tb, yrot_bxv, zrot_tb, zrot_bxv, fr_tb, fr_bxv, sl_xrot, sl_yrot, sl_zrot, sl_fr, c = imslice_gui_layout(img; lbl = lbl, clim = clim, xrot_init = xrot_init, yrot_init = yrot_init, zrot_init = zrot_init)
  # Pair z-index to section number.
  fx_fr_tforms = Vector{AbstractAffineMap}(undef,length(sectionindices))
  fx_mv_pairs = [Pair(nothing, i) for i in sectionindices]
  fx_mv_pairs = convert(Vector{Pair{Union{Nothing, Int}, Union{Nothing, Int}}}, fx_mv_pairs) #This way, fx_mv_pairs can have both nothing and Int.
  textstring = map(y -> isnothing(findfirst(map(first, fx_mv_pairs) .== y)) ? 0 : findfirst(map(first, fx_mv_pairs) .== y), sl_fr) #If functions are separated, it does not work. Receive text string from slider sl_fr. if sl_fr is the same as mv frame, assign 0. Otherwise, set to be `sl_fr`
  moving_fr_tb = textbox(Int; observable = textstring)
  map(_ -> textstring[], moving_fr_tb)
  set_gtk_property!(moving_fr_tb, :width_chars ,4)

  ## Pair button
  pair_but = button("Pair!")
  n = [false]
  previous_fx_fr = Vector{Union{Nothing, Int}}(undef, 1)
  previous_mv_fr = Vector{Union{Nothing, Int}}(undef, 1)
  previous_fx_fr[1] = nothing #Default is nothing
  previous_mv_fr[1] = nothing #Default is nothing 
  action_pair = map(pair_but) do val #When the button clicked
    if n[1] == true
      # Get fixed and moving frame index
      fixed_fr = parse(Int, get_gtk_property(fr_tb, "text", String))
      moving_fr = parse(Int, get_gtk_property(moving_fr_tb, "text", String))
      if Pair(fixed_fr, moving_fr) ∈ fx_mv_pairs
        fx_fr_tforms[moving_fr] = tform[1]
        println(Pair(fixed_fr, moving_fr)) #Somehow println function needs to be at the end of the "if syntax".
      else
        if moving_fr ∈  sectionindices #If moving_fr is in moving indices, run the below.
          previous_fx_fr[1] = first(fx_mv_pairs[moving_fr]) #assign previous_fx_fr as the current fixed_fr.
          fx_mv_pairs_idx = findfirst(map(first, fx_mv_pairs) .== fixed_fr)
          if isnothing(fx_mv_pairs_idx) #if `fx_mv_pairs` does not contain the current `fixed_fr`, do nothing. Else, in which `fx_mv_pairs` contains the current `fixed_fr`, update previous_mv_fr.
            previous_mv_fr[1] = nothing
          else
            previous_mv_fr[1] = fx_mv_pairs_idx #fx_mv_pairs_idx is the same as mv_fr.
          end
          fx_fr_tforms[moving_fr] = tform[1]
        end
        p = Pair(fixed_fr, moving_fr) #pair fixed_frame and moving frame
        if moving_fr == 0 # If moving_fr is set to be 0, initialize the pair.
          temp_mv_idx = findfirst(map(first, fx_mv_pairs) .== fixed_fr)
          if !isnothing(temp_mv_idx)
            fx_mv_pairs[temp_mv_idx] = Pair(nothing, temp_mv_idx)
            Base._unsetindex!(fx_fr_tforms, temp_mv_idx)
          end
        elseif !isequal(moving_fr, previous_mv_fr[1]) && moving_fr ∈ sectionindices #how does it work?
          if previous_mv_fr[1] != nothing #If the same moving frame was paired with another fixed frame, initialize the pre-existing pair.
            fx_mv_pairs[previous_mv_fr[1]] = Pair(nothing, previous_mv_fr[1])
            Base._unsetindex!(fx_fr_tforms, previous_mv_fr[1])
          end
          fx_mv_pairs[moving_fr] = p
        end
        println(p) #Somehow println function needs to be at the end of the "if syntax".
      end
    end
    n[1] = true #Somehow, the button is automatically clicked once. So, do nothing for this click.
  end

  ## Grid
  g = GtkGrid()
  g[1,1] = widget(xrot_tb)
  g[2,1] = xrot_bxv
  g[3,1] = widget(yrot_tb)
  g[4,1] = yrot_bxv
  g[5,1] = widget(zrot_tb)
  g[6,1] = zrot_bxv
  g[7,1] = widget(fr_tb)
  g[8,1] = fr_bxv
  g[9,1] = widget(moving_fr_tb)
  g[1:2,2] = widget(sl_xrot)
  g[3:4,2] = widget(sl_yrot)
  g[5:6,2] = widget(sl_zrot)
  g[7:8,2] = widget(sl_fr)
  g[9,2] = widget(pair_but)
  g[1:9,3] = widget(c)
  push!(win, g)

  return(tform, fx_fr_tforms, fx_mv_pairs)
end

""" Given the Pairs from imslice_gui, fixed-moving frame pairs will be interpolated
kwargs: 
`first_ref_match_frame` should be given when the reference frame corresponding to the first moving frame is known. Likewise, `last_ref_match_frame` should be given if the reference frame corresponding to the last moving frame is known.
"""
function update_image_pairs(ps; first_ref_match_frame = NaN, last_ref_match_frame = NaN)
  p1 = copy(ps)
  fxfrms = map(first, p1)
  idx = findall(fxfrms .!= nothing) #Find updated pairs
  if !isequal(first_ref_match_frame, NaN)
    if first_ref_match_frame != fxfrms[idx[1]]
      if idx[1] == 1
        @warn "The first fixed-moving frame pair will be overwriten."
      end
      p1[1] = Pair(first_ref_match_frame, 1)
    end
  end
  if !isequal(last_ref_match_frame, NaN)
    if last_ref_match_frame != fxfrms[idx[end]]
      if idx[end] == length(p1) 
        @warn "The last fixed-moving frame pair will be overwriten."
      end
      p1[end] = Pair(last_ref_match_frame, length(p1))
    end
  end
  fxfrms = map(first, p1)
  newidx = findall(fxfrms .!= nothing) #Find updated pairs
  fxfrms_output = Vector{Vector{Int}}() #initialize 
  for i in 1:length(newidx)-1
    fxfrms_interp = round.(Int, collect(range(fxfrms[newidx[i]], fxfrms[newidx[i+1]], newidx[i+1]-newidx[i]+1))) #identify fixed frame numbers.
    push!(fxfrms_output, fxfrms_interp[1:end-1])
  end
  fxfrms_vec = vcat(fxfrms_output...)
  push!(fxfrms_vec, fxfrms[newidx[end]])
  pairout = [Pair(first(v), last(v)) for v in zip(fxfrms_vec, collect(newidx[1]:newidx[end]))]
  return pairout
end

"""
Interpolation may be done by degree and warping. but for simplicity, just get the values from the prior vector index.
The fx_fr_tforms for the first frame must be given.
"""
function update_tforms(fx_fr_tforms::Vector; first_fr_tform = NaN)
  tforms = copy(fx_fr_tforms)
  if !isequal(first_fr_tform, NaN)
    @warn "The first tform may be overwritten."
    tforms[1] = first_fr_tform
  end
  keep = isassigned.((tforms,), 1:length(tforms))
  idx = findall(keep .== 0)
  for i in idx
    tforms[i] = tforms[i-1]
  end
  tforms
end

"""Interpolation function"""
interpfun(x, x1, y1, x2, y2) = y1+((x-x1)*(y2-y1))/(x2-x1)
interpfun(x, x1, y1::AbstractMatrix, x2, y2::AbstractMatrix) = y1.+((x-x1).*(y2.-y1))./(x2-x1)
