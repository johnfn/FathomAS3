package {
  public interface IPositionable {
    function get x():int;
    function set x(val:int):void;

    function get y():int;
    function set y(val:int):void;

    function add(v:IPositionable):IPositionable;
    function subtract(v:IPositionable):IPositionable;
    function multiply(n:int):IPositionable;
    function divide(n:int):IPositionable;
  }
}