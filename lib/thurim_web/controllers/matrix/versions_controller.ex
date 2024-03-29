defmodule ThurimWeb.Matrix.VersionsController do
  use ThurimWeb, :controller

  def client(conn, _params) do
    json(conn, %{
      versions: [
        "r0.0.1",
        "r0.1.0",
        "r0.2.0",
        "r0.3.0",
        "r0.4.0",
        "r0.5.0",
        "r0.6.0",
        "r0.6.1",
        "v1.1",
        "v1.2",
        "v1.3",
        "v1.4",
        "v1.5",
        "v1.6",
        "v1.7",
        "v1.8",
        "v1.9"
      ],
      unstable_features:
        %{
          #   "org.matrix.label_based_filtering": true,
          #   "org.matrix.e2e_cross_signing": true,
          #   "org.matrix.msc2432": true,
          #   "uk.half-shot.msc2666.query_mutual_rooms": true,
          #   "io.element.e2ee_forced.public": false,
          #   "io.element.e2ee_forced.private": false,
          #   "io.element.e2ee_forced.trusted_private": false,
          #   "org.matrix.msc3026.busy_presence": false,
          #   "org.matrix.msc2285.stable": true,
          #   "org.matrix.msc3827.stable": true,
          #   "org.matrix.msc3440.stable": true,
          #   "org.matrix.msc3771": true,
          #   "org.matrix.msc3773": false,
          #   "fi.mau.msc2815": false,
          #   "fi.mau.msc2659.stable": true,
          #   "org.matrix.msc3882": false,
          #   "org.matrix.msc3881": false,
          #   "org.matrix.msc3874": false,
          #   "org.matrix.msc3886": false,
          #   "org.matrix.msc3912": false,
          #   "org.matrix.msc3981": false,
          #   "org.matrix.msc3391": false,
          #   "org.matrix.msc4069": false
        }
    })
  end
end
