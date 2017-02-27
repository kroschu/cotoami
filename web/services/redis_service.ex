defmodule Cotoami.RedisService do
  require Logger
  
  @default_host "localhost"
  @default_port 6379
  
  @signin_key_expire_seconds 60 * 10
  @gravatar_key_expire_seconds 60 * 10
  
  def anonymous_key(anonymous_id), do: "anonymous-" <> anonymous_id
  
  def get_cotos(anonymous_id) do
    {:ok, conn} = start()
    cotos =
      case Redix.command(conn, ["LRANGE", anonymous_key(anonymous_id), "0", "1000"]) do
        {:ok, cotos} ->
          if cotos do
            Enum.map(cotos, fn coto ->
              Map.merge(Poison.decode!(coto), %{
                as_cotonoma: false, 
                cotonoma_key: ""
              })
            end)
          else
            []
          end
        {:error, reason} ->
          Logger.error "Redis error #{reason}"
          []
      end
    stop(conn)
    cotos
  end
  
  def add_coto(anonymous_id, coto) do
    coto_as_json = Poison.encode!(coto)
    {:ok, conn} = start()
    Redix.command!(conn, ["LPUSH", anonymous_key(anonymous_id), coto_as_json])
    stop(conn)
  end
  
  def clear_cotos(anonymous_id) do
    {:ok, conn} = start()
    Redix.command!(conn, ["DEL", anonymous_key(anonymous_id)])
    stop(conn)
  end
  
  def signin_key(token), do: "signin-" <> token
  
  def generate_signin_token(email) do
    {:ok, conn} = start()
    token = put_signin_token(conn, email)
    Redix.command!(conn, ["EXPIRE", signin_key(token), @signin_key_expire_seconds]) 
    stop(conn)
    token
  end
  
  # Ensure the newly generated signin token is unique
  defp put_signin_token(conn, email) do
    token = :crypto.strong_rand_bytes(30) |> Base.hex_encode32(case: :lower)
    case Redix.command!(conn, ["SETNX", signin_key(token), email]) do
      1 -> token
      0 -> put_signin_token(conn, email)
    end
  end
  
  def get_signin_email(token) do
    {:ok, conn} = start()
    email = Redix.command!(conn, ["GET", signin_key(token)])
    Redix.command!(conn, ["DEL", signin_key(token)])
    stop(conn)
    email
  end
  
  def gravatar_key(email), do: "gravatar-" <> email
  
  def get_gravatar_profile(email) do
    {:ok, conn} = start()
    gravatar = Redix.command!(conn, ["GET", gravatar_key(email)])
    stop(conn)
    gravatar
  end
  
  def put_gravatar_profile(email, profile_json) do
    {:ok, conn} = start()
    Redix.command!(conn, [
      "SETEX", 
      gravatar_key(email), 
      @gravatar_key_expire_seconds, 
      profile_json
    ])
    stop(conn)
  end
  
  defp host() do
    Application.get_env(:cotoami, __MODULE__, []) 
    |> Keyword.get(:host)
    || @default_host
  end
  
  defp start() do
    Redix.start_link(host: host(), port: @default_port)
  end
  
  defp stop(conn) do
    Redix.stop(conn)
  end
end
