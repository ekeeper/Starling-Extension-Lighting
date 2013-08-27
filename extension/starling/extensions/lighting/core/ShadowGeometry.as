package starling.extensions.lighting.core
{
	import starling.utils.MatrixUtil;
	import starling.display.DisplayObject;

	import flash.geom.Matrix;
	import flash.geom.Point;

	/**
	 * @author Szenia Zadvornykh
	 */
	public class ShadowGeometry
	{
		protected static var start:Point = new Point();
		protected static var end:Point = new Point();
		
		private var _modelEdges:Vector.<Edge>;
		private var _worldEdges:Vector.<Edge>;
		
		private var _displayObject:DisplayObject;
		
		private var _transformMatrix:Matrix;
		
		/**
		 * abstract baseclass to hold geometry used for shadow casting
		 * do NOT use this class, instead use QuadShadowGeometry, PolygonShadowGeometry or your own implementation
		 */
		public function ShadowGeometry(displayObject:DisplayObject)
		{
			_displayObject = displayObject;
			
			_transformMatrix = new Matrix();
			
			_modelEdges = createEdges();
			_worldEdges = new <Edge>[];
			
			var edge:Edge;
			var length:int = _modelEdges.length - 1;
			
			for (var i:int = length; i >= 0; i--)
			{
				_worldEdges.push(new Edge());
			}
			
			//transform();
		}
		
		/**
		 * override this method in a custom implementation to create more complex geometry<br>
     * 重写此方法创建一个定制的实现更复杂的几何
		 */
		protected function createEdges():Vector.<Edge>
		{
			return null;
		}
		
		final public function transform():void
		{
			var matrix:Matrix = _transformMatrix;
			var length:int = _modelEdges.length;
			var modelEdge:Edge, worldEdge:Edge;

			matrix.identity();
			
			MatrixUtil.prependMatrix(matrix, _displayObject.transformationMatrix);
			
			for (var i:int = length-1; i >=0; i--)
			{
				modelEdge = _modelEdges[i];
				worldEdge = _worldEdges[i];
				
				worldEdge.startX = matrix.a * modelEdge.startX + matrix.c * modelEdge.startY + matrix.tx;
				worldEdge.startY = matrix.b * modelEdge.startX + matrix.d * modelEdge.startY + matrix.ty;
				worldEdge.endX   = matrix.a * modelEdge.endX   + matrix.c * modelEdge.endY   + matrix.tx;
				worldEdge.endY   = matrix.b * modelEdge.endX   + matrix.d * modelEdge.endY   + matrix.ty;								
			}
		}
		
		final public function get worldEdges():Vector.<Edge>
		{
			return _worldEdges;
		}

		final public function get displayObject():DisplayObject
		{
			return _displayObject;
		}

		public function dispose():void
		{
			_displayObject = null;
			_modelEdges = null;
			_worldEdges = null;
			_transformMatrix = null;
		}
	}
}
