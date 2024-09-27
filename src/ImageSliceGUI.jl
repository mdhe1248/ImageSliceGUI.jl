module ImageSliceGUI
#using Gtk, Gtk.ShortNames, GtkObservables, Rotations, CoordinateTransformations, Images, StaticArrays
using Gtk4, GtkObservables, Rotations, CoordinateTransformations, Images, StaticArrays

export imslice_gui, update_image_pairs, update_tforms
include("imslice_gui.jl")

end
