defmodule CorpcrawlTest do
  use ExUnit.Case
  import CorpcrawlTest.Helpers

  test "get form" do
    Corpcrawl.get_10ks(2014, 4)
    |> Enum.take(50)
    |> Enum.map(fn fm ->
        assert fm.form_type == "10-K"
    end)
  end

  @tag timeout: 60_000
  test "get exhibit 22.1 from 10k list" do
    [{form, doc}] = [%{file_name: "edgar/data/320193/0001193125-14-383437.txt"}]
    |> Corpcrawl.get_ex221(1)

    assert doc.filename == "EX-21.16d783162dex211.htm"
    assert doc.sequence == "EX-21.16"
  end

  @tag timeout: 60_000
  test "get subsidiaries of newscorp" do
    subs = {%{}, fixture("newscorp")}
    |> List.wrap
    |> Corpcrawl.load_chunk
    |> Corpcrawl.find_subsidiaries

    five = Enum.at(subs, 5)
    last = List.last(subs)

    assert five == %{
      "Company Name" => "A.C.N. 163 565 955 Pty Limited",
      "Jurisdiction" => "Australia"
    }

    assert last == %{
      "Company Name" => "WSJ Commerce Solutions, Inc.",
      "Jurisdiction" => "United States of America"
    }
  end


  @tag timeout: 60_000
  test "get subsidiaries of apple" do
    subs = {%{}, fixture("apple")}
    |> List.wrap
    |> Corpcrawl.load_chunk
    |> Corpcrawl.find_subsidiaries


    assert subs == [%{"Jurisdiction" => "Apple Sales International",
     "ofIncorporation" => "Ireland"},
    %{"Jurisdiction" => "Apple Operations International",
     "ofIncorporation" => "Ireland"},
    %{"Jurisdiction" => "Apple Operations Europe", "ofIncorporation" => "Ireland"},
    %{"Jurisdiction" => "Braeburn Capital, Inc.",
     "ofIncorporation" => "Nevada,U.S."},
    %{"Jurisdiction" => " the names of other subsidiaries of AppleInc. areomitted because, considered in the aggregate, they would not constitute a significant subsidiary as of the end of the year covered by this report. ",
     "ofIncorporation" => "S-K,"}]

  end

end
