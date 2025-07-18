defmodule Hex.HTTP.CurlHttp do
  @moduledoc false

  def request(method, request, http_opts, opts, _profile) do
    {url, headers, content_type, body} = normalize_request(request)
    timeout = Keyword.get(http_opts, :timeout, 15000)
    
    curl_args = build_curl_args(method, url, headers, content_type, body, timeout)
    
    {output, exit_code} = System.cmd("curl", curl_args, stderr_to_stdout: true)
    
    if exit_code != 0 do
      raise "cURL failed with exit code #{exit_code}: #{output}"
    end
    
    parse_curl_output(output)
  end

  defp normalize_request({url, headers}) do
    {List.to_string(url), headers, nil, nil}
  end

  defp normalize_request({url, headers, content_type, body}) do
    {List.to_string(url), headers, List.to_string(content_type), body}
  end

  defp build_curl_args(method, url, headers, content_type, body, timeout) do
    args = [
      "-X", String.upcase(to_string(method)),
      "--max-time", to_string(div(timeout, 1000)),
      "--include",  # Include headers in output
      "--silent",
      "--show-error",
      "--location",  # Follow redirects
      "--max-redirs", "10"
    ]

    # Add headers
    args = Enum.reduce(headers, args, fn {name, value}, acc ->
      header_str = "#{List.to_string(name)}: #{List.to_string(value)}"
      acc ++ ["-H", header_str]
    end)

    # Add content type and body if present
    args = if content_type && body do
      args ++ ["-H", "Content-Type: #{content_type}", "--data-binary", "@-"]
    else
      args
    end

    args ++ [url]
  end

  defp parse_curl_output(output) do
    # Split by double CRLF to separate responses (in case of redirects)
    parts = String.split(output, "\r\n\r\n")
    
    # Find the last response (final response after redirects)
    {header_part, body_part} = case parts do
      [single_part] -> {single_part, ""}
      multiple_parts -> 
        # Last part is body, second-to-last is final response headers
        body = List.last(multiple_parts)
        headers = Enum.at(multiple_parts, -2)
        {headers, body}
    end
    
    lines = String.split(header_part, "\r\n")
    [status_line | header_lines] = lines
    
    # Parse status line: "HTTP/1.1 200 OK"
    [version, code_str, reason] = String.split(status_line, " ", parts: 3)
    code = String.to_integer(code_str)
    
    # Parse headers
    headers = Enum.map(header_lines, fn line ->
      case String.split(line, ": ", parts: 2) do
        [name, value] -> {String.to_charlist(String.downcase(name)), String.to_charlist(value)}
        [name] -> {String.to_charlist(String.downcase(name)), String.to_charlist("")}
      end
    end)
    
    {:ok, {{String.to_charlist(version), code, String.to_charlist(reason)}, headers, body_part}}
  end
end