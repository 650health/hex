defmodule Hex.HTTP.KatipoHttp do
  @moduledoc false

  @pool_name :hex_katipo_pool

  @doc """
  Starts Katipo and its connection pool.
  """
  def start do
    IO.puts("THIS IS THE NEW ONE!!!!!!")
    Code.ensure_loaded!(:wpool)
    Code.ensure_loaded!(:katipo)
    Code.ensure_loaded!(:katipo_pool)
    {:ok, _} = Application.ensure_all_started([:wpool, :katipo])
    {:ok, _} = :katipo_pool.start(@pool_name, 2, [])
  end

  @doc """
  Makes an HTTP request using Katipo client.

  Compatible with Hex.HTTP.CurlHttp.request/5 interface.
  """
  def request(method, request, http_opts, _opts, _profile) do
    {url, headers, content_type, body} = normalize_request(request)
    katipo_opts = build_katipo_opts(http_opts, headers, content_type, body)

    case make_katipo_request(method, url, katipo_opts) do
      {:ok, %{status: status, headers: response_headers, body: response_body}} ->
        version = {1, 1}
        status_code = status
        reason_phrase = status_phrase(status)
        formatted_headers = format_headers(response_headers)

        {:ok, {{version, status_code, reason_phrase}, formatted_headers, response_body}}

      {:error, %{code: _code, message: message}} ->
        {:error, {:katipo_error, message}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_request({url, headers}) do
    {to_string(url), headers, nil, nil}
  end

  defp normalize_request({url, headers, content_type, body}) do
    {to_string(url), headers, to_string(content_type), body}
  end

  defp build_katipo_opts(http_opts, headers, content_type, body) do
    base_opts = %{
      followlocation: true,
      maxredirs: 10,
      headers: convert_headers(headers, content_type)
    }

    base_opts
    |> maybe_add_timeout(http_opts)
    |> maybe_add_body(body)
  end

  defp convert_headers(headers, content_type) do
    header_list =
      Enum.map(headers, fn {name, value} ->
        {to_string(name), to_string(value)}
      end)

    case content_type do
      nil -> header_list
      ct -> [{"content-type", ct} | header_list]
    end
  end

  defp maybe_add_timeout(opts, http_opts) do
    case Keyword.get(http_opts, :timeout) do
      nil -> opts
      timeout -> Map.put(opts, :timeout_ms, timeout)
    end
  end

  defp maybe_add_body(opts, nil), do: opts
  defp maybe_add_body(opts, body), do: Map.put(opts, :body, body)

  defp make_katipo_request(method, url, opts) do
    case method do
      :get -> :katipo.get(@pool_name, url, opts)
      :post -> :katipo.post(@pool_name, url, opts)
      :put -> :katipo.put(@pool_name, url, opts)
      :patch -> :katipo.patch(@pool_name, url, opts)
      :delete -> :katipo.delete(@pool_name, url, opts)
      :head -> :katipo.head(@pool_name, url, opts)
      :options -> :katipo.options(@pool_name, url, opts)
      other -> {:error, {:unsupported_method, other}}
    end
  end

  defp format_headers(headers) do
    Enum.map(headers, fn {name, value} ->
      {String.to_charlist(name), String.to_charlist(value)}
    end)
  end

  defp status_phrase(100), do: ~c"Continue"
  defp status_phrase(101), do: ~c"Switching Protocols"
  defp status_phrase(200), do: ~c"OK"
  defp status_phrase(201), do: ~c"Created"
  defp status_phrase(202), do: ~c"Accepted"
  defp status_phrase(204), do: ~c"No Content"
  defp status_phrase(301), do: ~c"Moved Permanently"
  defp status_phrase(302), do: ~c"Found"
  defp status_phrase(304), do: ~c"Not Modified"
  defp status_phrase(307), do: ~c"Temporary Redirect"
  defp status_phrase(308), do: ~c"Permanent Redirect"
  defp status_phrase(400), do: ~c"Bad Request"
  defp status_phrase(401), do: ~c"Unauthorized"
  defp status_phrase(403), do: ~c"Forbidden"
  defp status_phrase(404), do: ~c"Not Found"
  defp status_phrase(405), do: ~c"Method Not Allowed"
  defp status_phrase(409), do: ~c"Conflict"
  defp status_phrase(422), do: ~c"Unprocessable Entity"
  defp status_phrase(429), do: ~c"Too Many Requests"
  defp status_phrase(500), do: ~c"Internal Server Error"
  defp status_phrase(502), do: ~c"Bad Gateway"
  defp status_phrase(503), do: ~c"Service Unavailable"
  defp status_phrase(504), do: ~c"Gateway Timeout"
  defp status_phrase(status), do: ~c"Unknown"
end
