////////////////////////////////////////////////////////////////////////////////
// TestLight
// Version 1.0
// Create 2013-6-10
////////////////////////////////////////////////////////////////////////////////
package starling.extensions.lighting.geometry {
  import starling.display.DisplayObject;
  import starling.extensions.lighting.core.Edge;
  import starling.extensions.lighting.core.ShadowGeometry;
  import starling.extensions.lighting.core.display.IrregularPolygon;
  import starling.utils.VertexData;
  
  /**
  * @author Szenia Zadvornykh
  * */
  public class IrregularPolygonShadowGeometry extends ShadowGeometry {
    //==========================================================================
    // Construction Function
    //==========================================================================
    public function IrregularPolygonShadowGeometry(displayObject:IrregularPolygon) {
      super(displayObject);
    }
    override protected function createEdges():Vector.<Edge> {
      var irregularPolygon:IrregularPolygon = displayObject as IrregularPolygon;
      var vertexData:VertexData = irregularPolygon.vertexData;
      var numEdges:int = vertexData.numVertices;
      
      var edges:Vector.<Edge> = new <Edge>[];
      var i:int = 0;
      while (i < numEdges - 1) {
        vertexData.getPosition(i, start);
        vertexData.getPosition(i + 1, end);
        edges.push(new Edge(start.x, start.y, end.x, end.y));
        i++;
      }
      vertexData.getPosition(i, start);
      vertexData.getPosition(0, end);
      edges.push(new Edge(start.x, start.y, end.x, end.y));
      
      return edges;
    }
  }
  //
}
//===========================================================================^O^