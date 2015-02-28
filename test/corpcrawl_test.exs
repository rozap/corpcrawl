defmodule CorpcrawlTest do
  use ExUnit.Case
  import CorpcrawlTest.Helpers

  test "get form" do
    Corpcrawl.get_10ks(2014, 4)
    |> Enum.take(10)
    |> Enum.map(fn fm ->
        assert fm.form_type == "10-K"
    end)
  end

  test "get exhibit 22.1 from 10k list" do
    [{form, subs}] = [%{file_name: "edgar/data/320193/0001193125-14-383437.txt"}]
    |> Corpcrawl.ten_k_to_subs(1)
    

    [%{location: "Ireland", name: "Apple Sales International"},
      %{location: "Ireland", name: "Apple Operations International"},
      %{location: "Ireland", name: "Apple Operations Europe"},
      %{location: "Nevada,U.S.", name: "Braeburn Capital, Inc."}, _] = subs

    IO.inspect form
  end

  test "get subsidiaries of newscorp, table" do
    [{%{}, subs}] = [{%{company_name: "newscorp"}, fixture("newscorp")}]
    |> Corpcrawl.load_forms
    |> IO.inspect


    five = Enum.at(subs, 5)
    last = List.last(subs)

    assert five == %{
      name: "A.C.N. 163 565 955 Pty Limited",
      location: "Australia"
    }

    assert last == %{
      name: "WSJ Commerce Solutions, Inc.",
      location: "United States of America"
    }
  end

  test "get subsidiaries of apple, table" do
    [{%{}, subs}] = [{%{}, fixture("apple")}] |> Corpcrawl.load_forms


    assert subs == [
      %{name: "Apple Sales International", location: "Ireland"},
      %{name: "Apple Operations International", location: "Ireland"},
      %{name: "Apple Operations Europe", location: "Ireland"},
      %{name: "Braeburn Capital, Inc.", location: "Nevada,U.S."},
      %{name: " the names of other subsidiaries of AppleInc. areomitted because, considered in the aggregate, they would not constitute a significant subsidiary as of the end of the year covered by this report. ",location: "S-K,"}]
  end


  test "get subs of flowers, p elements" do
    [{%{}, subs}] = [{%{company_name: "flowers"}, fixture("flowers")}]
    |> Corpcrawl.load_forms

    assert subs
    |> Enum.drop(4)
    |> Enum.take(2) == [
      %{name: "1-800-FLOWERS Team Services, Inc. (Delaware)"},
      %{name: "1-800-FLOWERS Retail, Inc. (Delaware)"}
    ]
  end

end
