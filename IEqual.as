package {
  public interface IEqual {
    // "Force" implementors of IEqual to use the _uid method.
    function get uid():int;
    function equals(other:IEqual):Boolean;
  }
}
