////////////////////////////////////////////////////////////////////////////////
// TestLight
// Version 1.0
// Create 2013-6-10
////////////////////////////////////////////////////////////////////////////////
package starling.extensions.lighting.core.display {
  import com.adobe.utils.AGALMiniAssembler;
  import com.polygon.Point;
  import com.polygon.Sweep;
  import com.polygon.SweepContext;
  import com.polygon.Triangle;
  
  import flash.display3D.Context3D;
  import flash.display3D.Context3DProgramType;
  import flash.display3D.Context3DVertexBufferFormat;
  import flash.display3D.IndexBuffer3D;
  import flash.display3D.VertexBuffer3D;
  import flash.geom.Matrix;
  import flash.geom.Rectangle;
  
  import starling.core.RenderSupport;
  import starling.core.Starling;
  import starling.display.DisplayObject;
  import starling.errors.MissingContextError;
  import starling.events.Event;
  import starling.extensions.lighting.util.PolyUitl;
  import starling.utils.VertexData;
  
  
  public class IrregularPolygon extends DisplayObject {
    private static const PROGRAM_NAME:String = "irregularPolygon";
    //==========================================================================
    // Construction Function
    //==========================================================================
    public function IrregularPolygon(nodes:Vector.<Point>, color:uint = 0xffffff, premultipliedAlpha:Boolean = false) {
      super();
      if (nodes.length < 3) throw new ArgumentError("Invalid number of nodes");
      $nodes = PolyUitl.makeAntclockwise(nodes);
      $color = color;
      $premultipliedAlpha = premultipliedAlpha;
      //设置顶点数据
      setupVertices();
      createBuffers();
      registerPrograms();
      //
      Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
    } 
    //==========================================================================
    // Properties
    //==========================================================================
    private var $nodes:Vector.<Point>;
    private var $color:uint;
    private var $premultipliedAlpha:Boolean;
    //vertex data 
    private var $vertexData:VertexData;
    private var $vertexBuffer:VertexBuffer3D;
    //index data
    private var $indexData:Vector.<uint>;
    private var $indexBuffer:IndexBuffer3D;
    //辅助对象(避开临时对象)
    private static const HELP_MATRIX:Matrix = new Matrix();
    private static const RENDER_ALPHA:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
    //==========================================================================
    //  getter/setter
    //==========================================================================
    /***/
    public function get numEdges():int {
      return $nodes.length;
    }
    /**颜色*/
    public function get color():uint {
      return $color;
    }
    public function set color(value:uint):void {
      if ($color == value)
        return;
      $color = value;
      setupVertices();
    }
    /***/
    public function get vertexData():VertexData {
      return $vertexData;
    }
    //==========================================================================
    // public Function
    //==========================================================================
    override public function dispose():void {
      Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
      if ($vertexBuffer) 
        $vertexBuffer.dispose();
      if ($indexBuffer) 
        $indexBuffer.dispose();
      super.dispose();
    }
    override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle {
      if (resultRect == null)
        resultRect = new Rectangle();
      
      var transformationMatrix:Matrix = targetSpace == this ? 
        null : getTransformationMatrix(targetSpace, HELP_MATRIX);
      
      return $vertexData.getBounds(transformationMatrix, 0, -1, resultRect);
    }
    
    override public function render(support:RenderSupport, parentAlpha:Number):void {
      support.finishQuadBatch();
      
      //RENDER_ALPHA[0] = RENDER_ALPHA[1] = RENDER_ALPHA[2] = 1.0;
      ///RENDER_ALPHA[3] = this.alpha * parentAlpha;
      
      var context:Context3D = Starling.context;
      if (context == null) throw new MissingContextError();
      
      support.applyBlendMode(false);
      context.setProgram(Starling.current.getProgram(PROGRAM_NAME));
      context.setVertexBufferAt(0, $vertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
      // StarlingFramework 1.3
      context.setVertexBufferAt(1, $vertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
      // update for StarlingFramework 1.4 rc1
      //context.setVertexBufferAt(1, $vertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.BYTES_4);
      //context.setVertexBufferAt( 0, $vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3 ); //va0 is position
      //context.setVertexBufferAt( 1, $vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_4 ); //va1 is color
      context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
      context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, RENDER_ALPHA, 1);
      //
      context.drawTriangles($indexBuffer, 0, ($indexData.length/3));
      support.raiseDrawCount(1);
      //
      context.setVertexBufferAt(0, null);
      context.setVertexBufferAt(1, null);
    }
    //==========================================================================
    // protected Function
    //==========================================================================
    
    //==========================================================================
    // private Function
    //==========================================================================
    private static function registerPrograms():void {
      var target:Starling = Starling.current;
      if (target.hasProgram(PROGRAM_NAME))
        return;
      // va0 -> position
      // va1 -> color
      // vc0 -> mvpMatrix (4 vectors, vc0 - vc3)
      // vc4 -> alpha
      
      var vertexProgramCode:String = 
        //"mov op, va0    \n" +    //copy position to output 
        //"mov v0, va1"; //copy color to varying variable v0
        "m44 op, va0, vc0 \n" + //
        "mul v0, va1, vc4 \n"; //
      
      var fragmentProgramCode:String =  
        "mov oc, v0";
      
      var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
      vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
      
      var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
      fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode);
      
      target.registerProgram(PROGRAM_NAME, vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
    }
    private function createBuffers():void {
      var context:Context3D = Starling.context;
      if (context == null)
        throw new MissingContextError();
      
      if ($vertexBuffer)
        $vertexBuffer.dispose();
      if ($indexBuffer)
        $indexBuffer.dispose();
      
      $vertexBuffer = context.createVertexBuffer($vertexData.numVertices, VertexData.ELEMENTS_PER_VERTEX);
      // StarlingFramework 1.3
      $vertexBuffer.uploadFromVector($vertexData.rawData, 0, $vertexData.numVertices);
      // update for StarlingFramework 1.4 rc1
      //$vertexBuffer.uploadFromByteArray($vertexData.rawData, 0, 0, $vertexData.numVertices);
      
      $indexBuffer = context.createIndexBuffer($indexData.length);
      $indexBuffer.uploadFromVector($indexData, 0, $indexData.length);
    }
    
    private function setupVertices():void {
      var i:int = 0, len:int = $nodes.length, p:Point;
      //create Vertices
      $vertexData = new VertexData($nodes.length, $premultipliedAlpha);
      $vertexData.setUniformColor($color);
      //
      var sc:SweepContext = new SweepContext();
      var swp:Sweep = new Sweep(sc);
      var ids:Array = new Array();
      sc.addPolyline($nodes);
      swp.triangulate();
      while (i < len) {
        p = $nodes[i];
        $vertexData.setPosition(i, p.x, p.y);
        ids[p.id] = i;
        i++;
      }
      
      // create indices that span up the triangles
      $indexData = new <uint>[];
      i = 0, len = sc.triangles.length;
      var j:int, t:Triangle; 
      while (i < len) {
        t = sc.triangles[i];
        i++;
        j = 0;
        while (j < 3) {
          $indexData.push(ids[t.points[j].id]);
          j++;
        }
      }
    }
    //==========================================================================
    // EventListener Function
    //==========================================================================
    private function onContextCreated(e:Event):void {
      createBuffers();
      registerPrograms();
    }
  }
  //
}
//===========================================================================^O^
