////////////////////////////////////////////////////////////////////////////////
// Poly2tri
// Version 1.0
// Create 2013-6-25
////////////////////////////////////////////////////////////////////////////////
package com.polygon {
  import flash.utils.Dictionary;
  
  public class Point {
    //==========================================================================
    // Construction Function
    //==========================================================================
    public function Point(x:Number = 0, y:Number = 0) {
      super();
      $x = x;
      $y = y;

      $id = C_ID;
      C_ID++;
    }
    //==========================================================================
    // private properties
    //==========================================================================
    public static var C_ID:int = 0;
    private var $id:int
    private var $x:Number;
    private var $y:Number;
    private var $edge_list:Vector.<Edge> = new Vector.<Edge>();
    //==========================================================================
    //  getter/setter
    //==========================================================================
    public function get edge_list():Vector.<Edge> {
      return $edge_list;
    }

    public function get y():Number {
      return $y;
    }
    public function set y(value:Number):void {
      if ($y == value)
        return;
      $y = value;
    }
    public function get x():Number {
      return $x;
    }
    public function set x(value:Number):void {
      if ($x == value)
        return;
      $x = value;
    }
    public function get id():int {
      return $id;
    }
    public function set id(value:int):void {
      if ($id == value)
        return;
      $id = value;
    }
    //==========================================================================
    // public Function
    //==========================================================================
    public function equals(that:Point):Boolean {
      return this.x == that.x && this.y == that.y;
    }
    public static function sortPoints(points:Vector.<Point>):void {
      points.sort(cmpPoints);
    }
    
    public static function cmpPoints(l:Point, r:Point):int {
      var ret:Number = l.y - r.y;
      if (ret == 0) ret = l.x - r.x;
      if (ret < 0) return -1;
      if (ret > 0) return 1;
      return 0;
    }
    public static function getUniqueList(nonUniqueList:Vector.<Point>):Vector.<Point> {
      var point:Point;
      var pointsMap:Dictionary = new Dictionary();
      var uniqueList:Vector.<Point> = new Vector.<Point>();
      
      for each (point in nonUniqueList) {
        var hash:String = String(point);
        if (pointsMap[hash] === undefined) {
          pointsMap[hash] = true;
          uniqueList.push(point);
        }
      }
      
      return uniqueList;
    }
    public function toString():String {
      return "Point (x = " + x + ", y = " + y + ")";
    }
    //==========================================================================
    // protected Function
    //==========================================================================
    public function get_edge_list():Vector.<Edge> {
      if ($edge_list == null)
        return $edge_list = new Vector.<Edge>();
      return $edge_list;
    }
    //==========================================================================
    // private Function
    //==========================================================================
    
    //==========================================================================
    // EventListener Function
    //==========================================================================
    
    
  }
  //
}
//===========================================================================^O^