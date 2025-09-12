#lang pollen

◊h1{Making Memes with Typst}

◊posting-date{2025-07-19}

◊section{
  I've been having fun using ◊a[#:href "https://typst.app/"]{Typst} to make various documents, and the thought struck me that I should try making a meme with it.

  Code:

  ◊code-listing["typst"]{
    #set text(48pt, font: "Impact", fill: white, stroke: (paint: black, thickness: 2pt))

    #image("griffin.jpg", width: 800pt)

    #place(
      center + bottom,
      dy: -10pt,
      [Don't use Typst to make memes],
    )
  }

  Command:

  ◊code-listing["sh"]{
    typst compile meme.typ --format png
  }

  Output: 

  ◊img[#:src "./meme.png" #:alt "An image of Peter Griffin running from an airplane with the caption \"Don't use Typst to make memes\""]
}
