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
class Shoes::StackLayout < Qt::VBoxLayout
  extend Forwardable
  # TODO most are still missing
  def_delegators :@layout, :add_widget#, :add_layout, :add_item, :remove_item,
    #:remove_widget, :remove_layout, :count
  def initialize
    super
    @layout = Qt::VBoxLayout.new
    add_layout(@layout, 0)
    add_stretch(1)
  end
end

class Shoes::App < Qt::Application
  def initialize blk
    super ARGV
    @_main_window = Qt::Widget.new do
      self.layout = Shoes::StackLayout.new
      resize 200, 400
    end
    @_current_widget = @_main_window

    instance_eval &blk

    @_main_window.show
    exec
    exit
  end
  def button txt, &blk
    b = Qt::PushButton.new txt do
      puts blk
      puts self
      #connect(SIGNAL :clicked) &blk if blk # TODO: not working ?????
      connect(SIGNAL :clicked) { blk.call } if blk
    end
    add_widget b
  end

  def add_widget widget
    @_current_widget.layout.add_widget widget, 0
  end
end

Shoes.app do
  button("Hello") { puts self }
  button "Another button"
end







#a = Qt::Application.new(ARGV)
#
#quit = Qt::PushButton.new('Quit', nil)
#quit.resize(75, 30)
#quit.setFont(Qt::Font.new('Times', 18, Qt::Font::Bold))
#
#Qt::Object.connect(quit, SIGNAL('clicked()'), a, SLOT('quit()'))
#
#quit.show
#a.exec
#exit



#require 'Qt4'
#
#Qt::Application.new(ARGV) do
#    Qt::Widget.new do
#
#        self.window_title = 'Hello QtRuby v1.0'
#        resize(200, 100)
#
#        button = Qt::PushButton.new('Quit') do
#            connect(SIGNAL :clicked) { puts "clicked" }
#        end
#
#        label = Qt::Label.new('<big>Hello Qt in the Ruby way!</big>')
#
#        self.layout = Qt::VBoxLayout.new do
#            add_widget(label, 0, Qt::AlignCenter)
#            add_widget(button, 0, Qt::AlignRight)
#        end
#
#        show
#    end
#
#    exec
#end