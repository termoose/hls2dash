defmodule Hls2dash do
  import XmlBuilder

  defmodule Playlist do
    defstruct base: "", segments: []
  end
  
  def parse(m3u8_url) do
    playlists = get_segments(m3u8_url)
    |> Enum.filter(&is_link?/1)
    |> Enum.map(&remove_newline/1)

    hd(playlists) |> to_playlist |> to_dash
  end

  def to_dash(%Playlist{base: base_url, segments: segment_list}) do
    element(:XPD, %{xmlns: "urn:mpeg:dash:schema:mpd:2011"}, [
          element(:BaseURL, base_url),
          element(:Period, %{}, [
                element(:AdaptationSet, %{mimeType: "video/mp2t"}, [
                      element(:Representation, %{id: "720p", bandwidth: "3200000", width: "1280", height: "720"}, [
                            element(:SegmentList, %{duration: "1"},
                                    Enum.map(segment_list,
                                      fn(segment) -> element(:SegmentURL, %{media: segment}) end))
											    ])
								    ])
					    ])
		    ])
    |> XmlBuilder.generate
    |> IO.puts
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
      "" -> false
      _ -> true
    end
  end

  def remove_newline(line) do
    String.replace(line, "\n", "")
  end
end
