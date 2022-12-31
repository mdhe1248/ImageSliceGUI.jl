#### Sliders
"""
kwargs:
`lbl` is window name. 
`clim` is contrast limit. .
default: 
lbl = "imsliceGUI"
clim = (0, maximum(img))
"""
function imslice_gui(img; lbl = "imsliceGUI", clim = (0, maximum(img)))
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
	c = canvas(UserUnit)
	set_gtk_property!(c, :expand, true)
	
	#### Draw functions
	sl_xrot[] = 0
	sl_yrot[] = 0
	sl_zrot[] = 0
	sl_fr[] = 1
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
	  nothing
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
end

## Draw

### Draw and zoom setup
#zr = Observable(ZoomRegion(img))
#imgroi = 
#map(zr) do r
#	cv = r.currentview   # extract the currently-selected region
#	view(img, UnitRange{Int}(cv.y), UnitRange{Int}(cv.x))
#end;
#
#draw(c, imgroi, zr) do cnvs, img, r
#  copy!(cnvs, img)
#  set_coordinates(cnvs, r)
#end
#
#rb = init_zoom_rubberband(c, zr)
#rb["enabled"][] = true
#pandrag = init_pan_drag(c, zr)
#showall(win)

##function set_aspect!(frame::AspectFrame, image)
##    ps = map(abs, pixelspacing(image))
##    sz = map(length, axes(image))
##    r = sz[2]*ps[2]/(sz[1]*ps[1])
##    set_gtk_property!(frame, :ratio, r)
##    nothing
##end

