package starling.extensions.lighting.core
{
  import com.adobe.utils.PerspectiveMatrix3D;
  
  import flash.display3D.Context3D;
  import flash.display3D.Context3DBlendFactor;
  import flash.display3D.Context3DClearMask;
  import flash.display3D.Context3DCompareMode;
  import flash.display3D.Context3DProgramType;
  import flash.display3D.Context3DStencilAction;
  import flash.display3D.Context3DTextureFormat;
  import flash.display3D.Context3DTriangleFace;
  import flash.display3D.Context3DVertexBufferFormat;
  import flash.display3D.IndexBuffer3D;
  import flash.display3D.VertexBuffer3D;
  import flash.display3D.textures.Texture;
  import flash.geom.Rectangle;
  import flash.geom.Point;
  
  import starling.core.RenderSupport;
  import starling.core.Starling;
  import starling.display.DisplayObject;
  import starling.extensions.lighting.lights.PointLight;
  import starling.extensions.lighting.shaders.LightMapShader;
  import starling.extensions.lighting.shaders.PointLightShader;
  import starling.extensions.lighting.shaders.PositionalLightShadowShader;
  import starling.utils.Color;
  import starling.utils.getNextPowerOfTwo;
  
  import starling.extensions.lighting.shaders.GaussianBlurShader;
  import starling.extensions.lighting.shaders.SpotLightShader;
  import starling.extensions.lighting.lights.SpotLight;
  import starling.extensions.lighting.shaders.DirectionalLightShadowShader;
  import starling.extensions.lighting.lights.DirectionalLight;
  import starling.extensions.lighting.shaders.DirectionalLightShader;
  
  /**
   * @author Szenia Zadvornykh
   *
   * original setup by Ryan Speets @ ryanspeets.com
   */
  public class LightLayer extends DisplayObject
  {
    public static var Program:String = "";
    
    private const VERTICES_PER_EDGE:uint = 4;
    private const INDICES_PER_EDGE:uint = 6;
    
    private var geometry:Vector.<ShadowGeometry>;
    private var geometryVertexBuffer:VertexBuffer3D;
    private var geometryIndexBuffer:IndexBuffer3D;
    private var geometryVertexCount:uint;
    
    private var vertices:Vector.<Number> = new <Number>[];
    private var indices:Vector.<uint> = new <uint>[];
    private var totalEdgeCount:uint = 0;
    
    private var lights:Vector.<LightBase>;
    
    private var pointLightShader:PointLightShader;
    private var pointLightShadowShader:PositionalLightShadowShader;
    private var directionalLightShader:DirectionalLightShader;
    private var directionalLightShadowShader:DirectionalLightShadowShader;
    private var spotLightShader:SpotLightShader;
    private var sceneShader:LightMapShader;
    private var blurShader:GaussianBlurShader;
    
    private var sceneVertexBuffer:VertexBuffer3D;
    private var sceneUVBuffer:VertexBuffer3D;
    private var sceneIndexBuffer:IndexBuffer3D;
    
    private var lightMapIn:Texture;
    private var lightMapOut:Texture;
    
    private var _width:int;
    private var _height:int;
    private var legalWidth:uint;
    private var legalHeight:uint;
    private var _shadowSoftness:Number;
    private var _boundsRect:Rectangle = new Rectangle();
    private var _scissorRectangle:Rectangle = new Rectangle();
    private var _renderMode:int;
    private var _relatedLayer:LightLayer;
    
    private var _projectionMatrix:PerspectiveMatrix3D;
    private var _contextVertexVector:Vector.<Number> = new <Number>[0, 1, 10000, 0];
    private var _contextFragmentVector:Vector.<Number> = new <Number>[1, 1, 1, 1];
    
    /**
     * v0.1
     *
     * Creates a new LightLayer display object. This must be added on top of any shadow casting objects.
     *
     * Light sources can be added with @see addLight
     * Shadow-casting geometry can be added with @see addGeometryForDisplayObject
     *
     * Current version can create shadow-casting geometry from Image, Quad and RegularPolygon (included in this package)
     * Shadow-casting geometry is created from VertexData (bounding box), not from pixels.
     *
     * @param width width of the display
     * @param height height of the display
     * @param ambientColor color of the ambient light, default black. This does not cast shadows.
     * @param ambientColorIntencity intencity of the ambient light. Values range from 0 to 1
     * @param shadowSoftness control how soft the shadow eges are. Minimum of 1
     */
    public function LightLayer(width:int, height:int, ambientColor:uint = 0x000000, ambientColorIntensity:Number = 1, shadowSoftness:Number = 1)
    {
      _width = width;
      _height = height;
      _shadowSoftness = shadowSoftness;
      _scissorRectangle.setTo(0, 0, _width, _height);
      
      lights = new <LightBase>[];
      geometry = new <ShadowGeometry>[];
      
      createScene();
      createShaders();
      
      setAmbientLightColor(ambientColor, ambientColorIntensity);
      
      touchable = false;
    }
    
    private function createScene():void
    {
      var context:Context3D = Starling.context;
      
      sceneVertexBuffer = context.createVertexBuffer(4, 2);
      sceneVertexBuffer.uploadFromVector(Vector.<Number>([-1, -1, 1, -1, 1, 1, -1, 1]), 0, 4);
      sceneUVBuffer = context.createVertexBuffer(4, 2);
      sceneUVBuffer.uploadFromVector(Vector.<Number>([0, 1, 1, 1, 1, 0, 0, 0]), 0, 4);
      sceneIndexBuffer = context.createIndexBuffer(6);
      sceneIndexBuffer.uploadFromVector(Vector.<uint>([0, 2, 1, 0, 3, 2]), 0, 6);
      
      legalWidth = getNextPowerOfTwo(_width);
      legalHeight = getNextPowerOfTwo(_height);
      
      lightMapIn = context.createTexture(legalWidth, legalHeight, Context3DTextureFormat.BGRA, true);
      lightMapOut = context.createTexture(legalWidth, legalHeight, Context3DTextureFormat.BGRA, true);
      
      _projectionMatrix = new PerspectiveMatrix3D();
      _projectionMatrix.orthoOffCenterLH(0, legalWidth, -legalHeight, 0, -1, 1);
    }
    
    private function createShaders():void
    {
      pointLightShader = new PointLightShader(legalWidth, legalHeight);
      pointLightShader.setDependencies(sceneVertexBuffer, sceneUVBuffer);
      
      spotLightShader = new SpotLightShader(legalWidth, legalHeight);
      spotLightShader.setDependencies(sceneVertexBuffer, sceneUVBuffer);
      
      directionalLightShader = new DirectionalLightShader();
      directionalLightShader.setDependencies(sceneVertexBuffer);
      
      pointLightShadowShader = new PositionalLightShadowShader();
      
      directionalLightShadowShader = new DirectionalLightShadowShader();
      
      blurShader = new GaussianBlurShader(legalWidth, legalHeight, _shadowSoftness >= 1 ? _shadowSoftness : 0);
      blurShader.setDependencies(lightMapIn, lightMapOut, sceneVertexBuffer, sceneUVBuffer);
      
      sceneShader = new LightMapShader(_width / legalWidth, _height / legalHeight);
      sceneShader.setDependencies(lightMapOut, sceneVertexBuffer, sceneUVBuffer);
    }
    
    /**
     * creates shadow casting edges for a display object.
     * @param geometry subclass of ShadowGeometry wrapped around a Starling display object.
     */
    public function addShadowGeometry(geometry:ShadowGeometry):void {
      this.geometry.push(geometry);
    }
    
    /**
     * remove shadow casting edges for a display object.
     */
    public function removeGeometryForDisplayObject(object:DisplayObject):void
    {
      var g:ShadowGeometry;
      var length:int = geometry.length - 1;
      
      for (var i:int = length; i >= 0; i--)
      {
        g = geometry[i];
        
        if (g && g.displayObject == object)
        {
          removeShadowGeometry(g);
          return;
        }
      }
    }
    
    /**
     * remove shadow casting edges directly
     */
    public function removeShadowGeometry(geometry:ShadowGeometry):void
    {
      this.geometry.splice(this.geometry.indexOf(geometry), 1);
      geometry.dispose();
    }
    
    /**
     * adds a light source to for shadow casting.
     * Each light requires two render calls.
     * @param light Light instance to be added
     */
    public function addLight(light:LightBase):void
    {
      lights.push(light);
    }
    
    /**
     * removes a light source.
     */
    public function removeLight(light:LightBase):void
    {
      lights.splice(lights.indexOf(light), 1);
    }
    
    /**
     * change ambient light color and intencity
     * @param ambientColor color of the ambient light, default black. This does not cast shadows.
     * @param ambientColorIntencity intencity of the ambient light. Values range from 0 to 1
     */
    public function setAmbientLightColor(color:uint, intensity:Number = 0):void
    {
      sceneShader.setAmbientColor(color, intensity);
    }
    
    override public function render(support:RenderSupport, parentAlpha:Number):void
    {
      var context:Context3D = Starling.context;
      
      support.finishQuadBatch();
      
      if (geometry.length > 0)
      {
        projectGeometry();
      }
      
      context.setRenderToTexture(lightMapIn, true);
      context.setScissorRectangle(_scissorRectangle);
      context.clear(0, 0, 0, 1, 1, 0, Context3DClearMask.ALL);
      
      context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _contextVertexVector);
      context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 2, _projectionMatrix, true);
      context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _contextFragmentVector);
      
      var l:LightBase;
      var length:int = lights.length - 1;
      
      for (var i:int = length; i >= 0; i--)
      {
        l = lights[i];
        
        if (l)
        {
          renderLight(support, l, context);
        }
      }
      
      renderLightMap(support, context);
      
      context.setBlendFactors(Context3DBlendFactor.ZERO, Context3DBlendFactor.ZERO);
      context.setVertexBufferAt(0, null);
      context.setVertexBufferAt(1, null);
      context.setTextureAt(0, null);
    }
    
    private function projectGeometry():void
    {
      var context:Context3D = Starling.context;
      var localEdgeCount:uint = 0;
      
      var edges:Vector.<Edge>, edge:Edge;
      var indexOffset:uint = 0, index:uint;
      var needsNewBuffer:Boolean;
      
      var verticesCount:int = 0;
      var indicesCount:int = 0;
      
      totalEdgeCount = 0;
      
      var shadowGeometry:ShadowGeometry;
      var length:int = geometry.length - 1;
      
      for (var i:int = length; i >= 0; i--)
      {
        shadowGeometry = geometry[i];
        
        if (shadowGeometry)
        {
          shadowGeometry.transform();
          
          edges = shadowGeometry.worldEdges;
          localEdgeCount = edges.length;
          totalEdgeCount += localEdgeCount;
          
          for (var j:int = localEdgeCount - 1; j >= 0; j--)
          {
            index = j * VERTICES_PER_EDGE + indexOffset;
            edge = edges[j];
            
            vertices[verticesCount++] = edge.startX;
            vertices[verticesCount++] = edge.startY;
            vertices[verticesCount++] = 1;
            vertices[verticesCount++] = edge.endX;
            vertices[verticesCount++] = edge.endY;
            vertices[verticesCount++] = 1;
            vertices[verticesCount++] = edge.endX;
            vertices[verticesCount++] = edge.endY;
            vertices[verticesCount++] = 0;
            vertices[verticesCount++] = edge.startX;
            vertices[verticesCount++] = edge.startY;
            vertices[verticesCount++] = 0;
            
            indices[indicesCount++] = index;
            indices[indicesCount++] = index + 2;
            indices[indicesCount++] = index + 1;
            indices[indicesCount++] = index;
            indices[indicesCount++] = index + 3;
            indices[indicesCount++] = index + 2;
          }
          
          indexOffset += (localEdgeCount * VERTICES_PER_EDGE);
        }
      }
      needsNewBuffer = !(geometryVertexCount == totalEdgeCount * VERTICES_PER_EDGE);
      
      geometryVertexCount = totalEdgeCount * VERTICES_PER_EDGE;
      
      if (needsNewBuffer)
      {
        if (geometryVertexBuffer)
          geometryVertexBuffer.dispose();
        geometryVertexBuffer = context.createVertexBuffer(geometryVertexCount, 3);
        
        if (geometryIndexBuffer)
          geometryIndexBuffer.dispose();
        geometryIndexBuffer = context.createIndexBuffer(totalEdgeCount * INDICES_PER_EDGE);
      }
      
      vertices.length = verticesCount;
      indices.length = indicesCount;
      
      geometryVertexBuffer.uploadFromVector(vertices, 0, geometryVertexCount);
      geometryIndexBuffer.uploadFromVector(indices, 0, indicesCount);
    }
    
    private function renderLight(support:RenderSupport, light:LightBase, context:Context3D):void
    {
      context.setDepthTest(false, Context3DCompareMode.ALWAYS);
      
      if (geometry.length > 0)
      {
        shadowPass(support, light, context);
      }
      
      lightPass(support, light, context);
      
      context.clear(0, 0, 0, 1, 1, 0, Context3DClearMask.STENCIL);
      context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
      context.setVertexBufferAt(0, null);
      context.setVertexBufferAt(1, null);
      context.setDepthTest(true, Context3DCompareMode.LESS);
    }
    
    private function shadowPass(support:RenderSupport, light:LightBase, context:Context3D):void
    {
      switch (true)
      {
        case light is PointLight: 
          pointLightShadowShader.setDependencies(geometryVertexBuffer, PointLight(light).x, PointLight(light).y);
          pointLightShadowShader.activate(context);
          break;
        case light is DirectionalLight: 
          directionalLightShadowShader.setDependencies(geometryVertexBuffer, light as DirectionalLight);
          directionalLightShadowShader.activate(context);
          break;
        case light is SpotLight: 
          pointLightShadowShader.setDependencies(geometryVertexBuffer, SpotLight(light).x, SpotLight(light).y);
          pointLightShadowShader.activate(context);
          break;
        default: 
          throw new ArgumentError("unsupported light type");
      }
      
      context.setStencilReferenceValue(1);
      context.setStencilActions(Context3DTriangleFace.FRONT, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
      context.setColorMask(false, false, false, false);
      
      context.drawTriangles(geometryIndexBuffer);
      support.raiseDrawCount(1);
    }
    
    private function lightPass(support:RenderSupport, light:LightBase, context:Context3D):void {
      switch (true) {
        case light is PointLight: 
          pointLightShader.light = light as PointLight;
          pointLightShader.activate(context);
          break;
        case light is DirectionalLight: 
          directionalLightShader.light = light as DirectionalLight;
          directionalLightShader.activate(context);
          break;
        case light is SpotLight: 
          spotLightShader.light = light as SpotLight;
          spotLightShader.activate(context);
          break;
        default: 
          throw new ArgumentError("unsupported light type");
      }
      
      context.setStencilReferenceValue(0);
      context.setStencilActions(Context3DTriangleFace.FRONT, Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
      context.setColorMask(true, true, true, true);
      context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
      
      context.drawTriangles(sceneIndexBuffer);
      support.raiseDrawCount(1);
    }
    
    private function renderLightMap(support:RenderSupport, context:Context3D):void {
      //context.setRenderToTexture(lightMapOut);
      //context.setTextureAt(0, lightMapIn);
      blurShader.activate(context);
      context.drawTriangles(sceneIndexBuffer);
      
      blurShader.activateSecondPass(context);
      context.drawTriangles(sceneIndexBuffer);
      
      context.setRenderToBackBuffer();
      context.setDepthTest(false, Context3DCompareMode.ALWAYS);
      context.setScissorRectangle(null);
      
      sceneShader.activate(context);
      context.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
      context.drawTriangles(sceneIndexBuffer);
      
      support.raiseDrawCount(3);
    }
    
    public function copyGeometryFrom(layer:LightLayer):void
    {
      geometry.length = 0;
      geometry.concat(layer.geometry);
    }
    
    override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
    {
      _boundsRect.setTo(0, 0, _width, _height);
      
      return _boundsRect;
    }
    
    public override function dispose():void
    {
      lights.length = 0;
      geometry.length = 0;
      
      sceneVertexBuffer.dispose();
      sceneUVBuffer.dispose();
      sceneIndexBuffer.dispose();
      
      if (geometryVertexBuffer)
        geometryVertexBuffer.dispose();
      if (geometryIndexBuffer)
        geometryIndexBuffer.dispose();
      
      lightMapIn.dispose();
    }
  }
}
