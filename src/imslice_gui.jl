using Gtk, Gtk.ShortNames, GtkObservables, Rotations, CoordinateTransformations, Images, StaticArrays

#### Sliders
"""
kwargs:
`lbl` is window name. 
`clim` is contrast limit. .
`xrot_init`, `yrot_init`, `zrot_init` in degree for the initial rotations
Additionally, `nmovingfrms` should be the number of the moving image frames to be registered.
default: 
lbl = "imsliceGUI"
clim = (0, maximum(img))
xrot_init = yrot_init = zrot_init = 0
nmovingfrms = NaN

tform = imslice_gui(img)
The output is transform (rotation).

if `nmovingfrms` are given:
tform, ps = imslice_gui(img; nmovingfrms = 51)
The outputs are transform (rotation) and reference-moving image pairs.
"""
function imslice_gui(img; lbl = "imsliceGUI", clim = (0, maximum(img)), xrot_init = 0, yrot_init = 0, zrot_init = 0, nmovingfrms = NaN)
  scalefun = scaleminmax(clim...)
  img = scalefun.(img)

  #### Window
  win = Window(lbl)

  ## Sliders
  sl_xrot = slider(0:360)
  sl_yrot = slider(0:360)
  sl_zrot = slider(0:360)
  frng = ceil(Int, sqrt(sum([size(img).^2...]))) #Frame range
  sl_fr = slider(-frng:frng)

  #### Canvas
  #frame, c = ImageView.frame_canvas(:auto)
  c = canvas(UserUnit)
  set_gtk_property!(c, :expand, true)

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
  xrot_bxv = Box(:v)
  push!(xrot_bxv, xrot_up_but)
  push!(xrot_bxv, xrot_dn_but)
  yrot_bxv = Box(:v)
  push!(yrot_bxv, yrot_up_but)
  push!(yrot_bxv, yrot_dn_but)
  zrot_bxv = Box(:v)
  push!(zrot_bxv, zrot_up_but)
  push!(zrot_bxv, zrot_dn_but)
  fr_bxv = Box(:v)
  push!(fr_bxv, fr_up_but)
  push!(fr_bxv, fr_dn_but)

  #### text box: Pair fixed and moving.
  if !isnan(nmovingfrms)
    mv_fx_pairs = [Pair(0, i) for i in 1:nmovingfrms]
    textstring = map(y -> isnothing(findfirst(x -> x == y, map(k -> first(k), mv_fx_pairs))) ? 0 : findfirst(x -> x == y, map(k -> first(k), mv_fx_pairs)), sl_fr) #If functions are separated, it does not work
    moving_fr_tb = textbox(Int; observable = textstring)
    map(_ -> textstring[], moving_fr_tb)
    set_gtk_property!(moving_fr_tb, :width_chars ,4) 

    ## Pair button
    pair_but = button("Pair!")
    action_pair = map(pair_but) do val
      println("pushed")
      fixed_fr = parse(Int, get_gtk_property(fr_tb, "text", String))
      moving_fr = parse(Int, get_gtk_property(moving_fr_tb, "text", String))
      p = Pair(fixed_fr, moving_fr)
      if moving_fr != 0 
        mv_fx_pairs[moving_fr] = p
        println(p) #Somehow println function needs to be at the end of if syntax.
      end
    end
    ## Grid 
    g = GtkGrid()
    g[1,1] = xrot_tb
    g[2,1] = xrot_bxv
    g[3,1] = yrot_tb
    g[4,1] = yrot_bxv
    g[5,1] = zrot_tb
    g[6,1] = zrot_bxv
    g[7,1] = fr_tb
    g[8,1] = fr_bxv
    g[9,1] = moving_fr_tb
    g[1:2,2] = sl_xrot
    g[3:4,2] = sl_yrot
    g[5:6,2] = sl_zrot
    g[7:8,2] = sl_fr
    g[9,2] = pair_but 
    g[1:9,3] = c
    push!(win, g)
    showall(win) ## Show all
    return(tform, mv_fx_pairs)
  else !isnan(nmovingfrms)
    ## No text box and botton for moving - fixed pair
    g = GtkGrid()
    g[1,1] = xrot_tb
    g[2,1] = xrot_bxv
    g[3,1] = yrot_tb
    g[4,1] = yrot_bxv
    g[5,1] = zrot_tb
    g[6,1] = zrot_bxv
    g[7,1] = fr_tb
    g[8,1] = fr_bxv
    g[1:2,2] = sl_xrot
    g[3:4,2] = sl_yrot
    g[5:6,2] = sl_zrot
    g[7:8,2] = sl_fr
    g[1:8,3] = c
    push!(win, g)
    showall(win) ## Show all
    return(tform)
  end
end

""" Given the Pairs from imslice_gui, fixed-moving frame pairs will be interpolated
kwargs: 
`first_ref_match_frame` should be given when the reference frame corresponding to the first moving frame is known. Likewise, `last_ref_match_frame` should be given if the reference frame corresponding to the last moving frame is known.
"""
function update_image_pairs(ps; first_ref_match_frame = NaN, last_ref_match_frame = NaN)
  p1 = copy(ps)
  fxfrms = map(first, p1)
  idx = findall(fxfrms .> 0) #Find updated pairs
  if isa(first_ref_match_frame, Int)
    if first_ref_match_frame != fxfrms[idx[1]]
      if idx[1] == 1
        @warn "The first fixed-moving frame pair will be overwriten."
      end
      p1[1] = Pair(first_ref_match_frame, 1)
    end
  end
  if isa(last_ref_match_frame, Int)
    if last_ref_match_frame != fxfrms[idx[end]]
      if idx[end] == length(p1) 
        @warn "The last fixed-moving frame pair will be overwriten."
      end
      p1[end] = Pair(last_ref_match_frame, length(p1))
    end
  end
  fxfrms = map(first, p1)
  newidx = findall(fxfrms .> 0) #Find updated pairs
  fxfrms_output = Vector{Vector{Int}}() #initialize 
  for i in 1:length(idx)-1
    fxfrms_interp = round.(Int, collect(range(fxfrms[newidx[i]], fxfrms[newidx[i+1]], newidx[i+1]-newidx[i]+1))) #identify fixed frame numbers.
    push!(fxfrms_output, fxfrms_interp[1:end-1])
  end
  fxfrms_vec = vcat(fxfrms_output...)
  push!(fxfrms_vec, fxfrms[newidx[end]])
  pairout = [Pair(first(v), last(v)) for v in zip(fxfrms_vec, collect(newidx[1]:newidx[end]))]
  return pairout
end
