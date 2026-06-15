defmodule ThurimMedia.Router do
  use ThurimApiHelpers.ThurimRouter

  # Enable LiveDashboard in development
  if Application.compile_env(:thurim_media, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ThurimMedia.Telemetry
    end
  end

  scope "/", ThurimMedia do
    pipe_through :access_token

    get "/config", ConfigController, :show

    get "/download/:server_name/:media_id", DownloadController, :show
    get "/download/:server_name/:media_id/:filename", DownloadController, :show
    get "/preview_url", DownloadController, :preview
    get "/thumbnail/:server_name/:media_id", DownloadController, :thumbnail
  end

  scope "/v1", ThurimMedia do
    pipe_through :access_token

    post "/create", UploadController, :create
  end

  scope "/v3", ThurimMedia do
    pipe_through :access_token

    post "/upload", UploadController, :upload
    put "/upload/:server_name/:media_id", UploadController, :upload
  end
end
