defmodule Hls2dash do
  import XmlBuilder

  defmodule Playlist do
    defstruct base: "", segments: []
  end
  
  def parse do
    stream = File.stream!("playlist.m3u8")

    stream
    |> Stream.filter(&is_link?/1)
    |> Stream.map(&remove_newline/1)
    |> Stream.map(&to_playlist/1)
    #|> Stream.map(&get_segments/1)
    |> Enum.map(fn(x) -> x end)
  end

  def to_dash(data) do
    {:XPD, %{xmlns: "urn:mpeg:dash:schema:mpd:2011",
             profiles: "urn:mpeg:dash:profile:full:2011",
             minBufferTime: "PT1.5S"},
     [{:Period, "test"}]
    }
    |> XmlBuilder.generate
  end

  def get_baseurl(url) do
    uri = URI.parse(url)
    uri.scheme <> "://" <> Path.join([uri.host, Path.dirname(uri.path)])
  end

  def to_playlist(url) do
    %Playlist{base: get_baseurl(url), segments: get_segments(url)}
  end

  def get_segments(link) do
    HTTPoison.get!(link).body
    |> String.split("\n")
    |> Enum.filter(&is_link?/1)
    |> Enum.map(&remove_newline/1)
  end
  
  def is_link?(line) do
    case line do
      "#" <> _rest -> false
      _ -> true
    end
  end

  def remove_newline(line) do
    String.replace(line, "\n", "")
  end
end