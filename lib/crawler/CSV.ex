defmodule Crawler.CSV do
  NimbleCSV.define(MyParser, separator: "\t", escape: "\"")
end
