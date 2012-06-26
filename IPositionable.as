package {
  public interface IPositionable {
    function get x():Number;
    function get y():Number;

    function setX(n:Number):IPositionable;
    function setY(n:Number):IPositionable;
    function setXY(x:Number, y:Number):IPositionable;

    function map(f:Function):IPositionable;

    function add(v:IPositionable):IPositionable;
    function subtract(v:IPositionable):IPositionable;
    function multiply(n:*):IPositionable;
    function divide(n:*):IPositionable;
  }
}