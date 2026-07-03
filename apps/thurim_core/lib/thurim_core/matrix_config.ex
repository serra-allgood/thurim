defmodule ThurimCore.MatrixConfig do
  @matrix_config Application.compile_env(:thurim_core, :matrix)

  def admin_email do
    @matrix_config[:admin_contact][:email]
  end

  def admin_mx_id do
    @matrix_config[:admin_contract][:matrix_id]
  end

  def auth_flows do
    @matrix_config[:auth_flows]
  end

  def auth_flow_types do
    @matrix_config[:auth_flow_types]
  end

  def default_power_levels do
    @matrix_config[:room_config][:default_power_levels]
  end

  def default_room_version do
    @matrix_config[:room_config][:default_room_version]
  end

  def homeserver_url do
    @matrix_config[:homeserver_url]
  end

  def identity_server_url do
    @matrix_config[:identity_server_url]
  end

  def max_token_age do
    @matrix_config[:max_token_age]
  end

  def server_name do
    @matrix_config[:domain]
  end

  def supported_room_versions do
    @matrix_config[:room_config][:supported_room_versions]
  end
end
