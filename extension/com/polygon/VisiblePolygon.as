////////////////////////////////////////////////////////////////////////////////
// Poly2tri
// Version 1.0
// Create 2013-6-25
////////////////////////////////////////////////////////////////////////////////
package com.polygon {
  import flash.display.Graphics;
  
  public class VisiblePolygon {
    //==========================================================================
    // Construction Function
    //==========================================================================
    public function VisiblePolygon() {
      super();
      reset();
    }
    //==========================================================================
    // private properties
    //==========================================================================
    private var sweepContext:SweepContext;
    private var sweep:Sweep;
    private var triangulated:Boolean;
    //==========================================================================
    // public Function
    //==========================================================================
    public function reset():void {
      sweepContext = new SweepContext();
      sweep = new Sweep(sweepContext);
      triangulated = false;
    }
    public function addPolyline(polyline:Vector.<Point>):void {
      sweepContext.addPolyline(polyline);
    }
    public function performTriangulationOnce():void {
      if (triangulated)
        return;
      triangulated = true;
      sweep.triangulate();
    }
    /**
    * @return vertices in a 3D engine-friendly, XYZ format
    * */
    public function getVerticesAndTriangles():Object {
      if (!triangulated)
        return null;
      var vertices:Vector.<Number> = new Vector.<Number>();
      var ids:Array = new Array();
      var i:int = 0, len:int = sweepContext.points.length;
      while (i < len) {
        var p:Point = sweepContext.points[i];
        vertices.push(p.x);
        vertices.push(p.y);
        vertices.push(0);
        ids[p.id] = i;
        i++;
      }
      
      var t:Triangle;
      var tris:Vector.<int> = new Vector.<int>();
      i = 0, len = sweepContext.triangles.length;
      var j:int; 
      while (i < len) {
        t = sweepContext.triangles[i];
        i++;
        j = 0;
        while (j < 3) {
          tris.push(ids[t.points[j].id]);
          j++;
        }
      }
      /*for each(t in sweepContext.triangles) {
        for (var j:int = 0; j < 3; j++) {
          tris.push(ids[t.points[j].id]);
        }
      }*/
      return {vertices: vertices, triangles:tris};
    }
    public function getNumTriangles():int {
      return sweepContext.triangles.length;
    }
    
    //if (nme || flash)
    public function drawShape(g:Graphics):void {
      var t:Triangle;
      var pl:Vector.<Point>;
      
      performTriangulationOnce();
      
      for each(t in sweepContext.triangles) 
      {
        pl = t.points;
        
        g.beginFill( 0xefb83d, .9 );
        g.moveTo(pl[0].x, pl[0].y);
        g.lineTo(pl[1].x, pl[1].y);
        g.lineTo(pl[2].x, pl[2].y);
        g.lineTo(pl[0].x, pl[0].y);
        g.endFill();
      }
      
      g.lineStyle(1, 0xd31205, 1);
      
      for each(t in sweepContext.triangles) 
      {
        pl = t.points;
        
        g.moveTo(pl[0].x, pl[0].y);
        g.lineTo(pl[1].x, pl[1].y);
        g.lineTo(pl[2].x, pl[2].y);
        g.lineTo(pl[0].x, pl[0].y);
      }
      
      g.lineStyle(2, 0x945922, 2);
      
      for each(var e:* in sweepContext.edge_list)
      {
        g.moveTo(e.p.x, e.p.y);
        g.lineTo(e.q.x, e.q.y);
      }
    }
    //==========================================================================
    // protected Function
    //==========================================================================
    
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