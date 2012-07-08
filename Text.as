package {
  import flash.text.TextField;
  import flash.geom.Point;
  import flash.utils.getQualifiedClassName;

  import Hooks;
  import Util;
  import MagicArray;

  public class Text extends Entity implements IEqual {
    internal var textField:TextField;

    function Text(x:Number = 0, y:Number = 0, content:String = ""):void {
      super(0, 0, 0, 0);
      mc.graphics.clear();

      textField = new TextField();
      textField.selectable = false;
      textField.x = x;
      textField.y = y;
      textField.text = content;

      Util.stage.addChild(textField);
    }
  }
}
