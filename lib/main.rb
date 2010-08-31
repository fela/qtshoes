#!/usr/bin/env ruby

$VERBOSE = true
$:.unshift File.dirname($0)

require 'Qt4'


module Shoes
  def self.app &blk
    # block is passed as proc to not trigger the qtruby initialization
    Shoes::App.new blk
  end
end

require 'forwardable'
class Shoes::StackLayout < Qt::GraphicsLinearLayout
  def add_item_orig *args, &blk
    addItem *args, &blk
  end
  extend Forwardable
  # TODO most methods are still missing
  def_delegators :@layout, :add_item#, :add_layout, :add_item, :remove_item,
    #:remove_widget, :remove_layout, :count
  def initialize
    super
    self.orientation = Qt::Vertical
    @layout = Qt::GraphicsLinearLayout.new do
      self.orientation = Qt::Vertical
    end
    item = Qt::GraphicsWidget.new
    item.layout = @layout
    add_item_orig(item)
    add_stretch(1)
    #void setStretchFactor ( QGraphicsLayoutItem * item, int stretch )
  end
end

class Shoes::FlowLayout < Qt::GraphicsLayout
  def initialize
    super
    @item_list = []
  end

  def add_item item
    @item_list << item
  end


  # overwrite the methods that are virtual in Qt
  def count
    @item_list.size
  end

  def item_at index
    @item_list[index]
  end

  def remove_at index
    @item_list.delete_at index
  end

  def size_hint which, constraint=Qt::SizeF
    puts "size hint"
    self.minimum_size
  end

  def minimum_size
    size = Qt::SizeF.new
    @item_list.each do |item|
     size = size.expanded_to item.minimum_size
    end

    #size += QSize(2*margin(), 2*margin());
    size
  end

  def set_geometry rect
    super rect
    do_layout rect
  end

  def do_layout rect
    x = y = 0
    row_height = 0
    max_width = self.preferred_size.width
    puts max_width
    @item_list.each do |item|
      rect = item.bounding_rect
      row_height = rect.height if rect.height > row_height
      item.x, item.y = x, y
      if x > max_width && rect.width < max_width
        # start a new row
        x = 0
        y += row_height
        row_height = rect.height
      end
      item.x, item.y = x, y
      x += rect.width
    end
  end

  def updateGeometry
    puts "update"
  end

  alias itemAt item_at
  alias removeAt remove_at
  alias sizeHint size_hint
  alias minimumSize minimum_size
  alias setGeometry set_geometry
end


class Shoes::App < Qt::Application
  def initialize blk
    super ARGV
    @_scene = Qt::GraphicsScene.new

    @_current_widget = Qt::GraphicsWidget.new do
      self.layout = Shoes::StackLayout.new
      puts self.layout
    end
    @_scene.add_item @_current_widget

    widget = @_current_widget
    #init_scene
    @_main_window = Qt::GraphicsView.new @_scene do
      self.frame_style = Qt::Frame::NoFrame
      @widget = widget

      # adapt scene to the window size:
      def resize_event event
        @widget.size = event.size
        scene.scene_rect =
          Qt::RectF.new(0, 0, event.size.width, event.size.height)
      end
      alias resizeEvent resize_event
      
      resize 200, 400
    end

    instance_eval &blk

    @_main_window.show
    exec
    exit
  end
  def button txt, &blk
    b = Qt::PushButton.new txt do
      #connect(SIGNAL :clicked) &blk if blk # TODO: not working ?????
      connect(SIGNAL :clicked) { blk.call } if blk
    end
    add_widget b
    b
  end
  def para txt
    txt.split(/\s+/).each do |word|
      text_item word
    end
  end

private
  def text_item txt
    t = Qt::GraphicsTextItem.new txt
    t.text_interaction_flags = Qt::TextBrowserInteraction
    add_item t
    t
  end

  def add_item item
    widget = Qt::GraphicsWidget.new
    item.parent_item = widget
    @_scene.add_item widget
    @_current_widget.layout.add_item widget
  end

  def add_widget widget
    proxy = @_scene.add_widget(widget)
    @_current_widget.layout.add_item proxy
  end
end

Shoes.app do
  button("Hello") { puts self }
  button "Another button"
  button "b2"
  button "b3"
  button "button"
  button "bb"
  para "hello, this is a para. A quite long para actually"
  para "para 2"
end
