////////////////////////////////////////////////////////////////////////////////
// TestLight
// Version 1.0
// Create 2013-6-26
////////////////////////////////////////////////////////////////////////////////
package starling.extensions.lighting.util {
  import com.polygon.Point;
  
  public class PolyUitl {
    //==========================================================================
    // Construction Function
    //==========================================================================
    public function PolyUitl() {
      throw new Error("10005", 40000);
    }
    //==========================================================================
    // private properties
    //==========================================================================
    /**
     * 10的-8次方值
     * */
    private static const eps:Number = 1e-8;
    //==========================================================================
    // public Function
    //==========================================================================
    /**
     * 计算多边形的有向面积
     * */
    public static function signArea(ps:Vector.<Point>):Number {
      var i:int = 0, len:int = ps.length, g:int, ans:Number = 0;
      while (i < len) {
        g = trim(i+1, len);
        ans += (ps[g].y * ps[i].x - ps[g].x * ps[i].y);
        i++;
      }
      return ans * .5;
    }
    /**
     * 判断多边形的点是逆时针顺序, 面积值为正，否则为负
     * @return -1, 1 或 0
     * */
    public static function sign(d:Number):int {
      return (d < -eps) ? -1 : (d > eps) ? 1 : 0;
    }
    /**
     * 判断多边形的顶点顺序是否为逆时针, 如果源顶点为顺时针的, 则调整为逆时针的
     * @param polyPoints 为已同一方向的多边形顶点数组
     * @return 逆时针方向顺序的顶点
     * */
    public static function makeAntclockwise(polyPoints:Vector.<Point>):Vector.<Point> {
      var r:Number = sign(signArea(polyPoints));
      if (r < 0) {
        //trace("原顶点顺序为顺时针方向","PolyUitl.makeAntclockwise(org)");
        polyPoints.reverse();
      }
      if (r > 0) {
        //trace("原顶点顺序为逆时针方向","PolyUitl.makeAntclockwise(org)");
      }
      if (r == 0) {
        //trace("在同一直线上","PolyUitl.makeAntclockwise(org)");
      }
      return polyPoints;
    }
    public static function trim(k:int, pn:int):int {
      return (k+pn)%pn;
    }
  }
  //
}
//===========================================================================^O^