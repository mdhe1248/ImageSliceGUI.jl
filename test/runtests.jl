using ImageSliceGUI
using CoordinateTransformations, Rotations, StaticArrays, Images
using Test


@testset "ImageSliceGUI.jl" begin
    # Write your tests here.

  img = rand(100,100,20)
  tform, tforms, ps = imslice_gui1(img; movingindices = 1:12)
  ps1 = update_image_pairs(ps)
  tforms1 = update_tforms(tforms)

end
