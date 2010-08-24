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


class Shoes::App < Qt::Application
  def initialize blk
    super ARGV
    @_scene = Qt::GraphicsScene.new

    @_current_widget = Qt::GraphicsWidget.new do
      self.layout = Shoes::StackLayout.new
    end
    @_scene.add_item @_current_widget

    widget = @_current_widget
    #init_scene
    @_main_window = Qt::GraphicsView.new @_scene do
      self.frame_style = Qt::Frame::NoFrame
      @widget = widget
      def resizeEvent event
        @widget.size = event.size
        scene.scene_rect =
          Qt::RectF.new(0, 0, event.size.width, event.size.height)
      end
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
  para "hello, this is a para"
end
