pragma solidity ^0.4.19;

contract ICOParams {
  //R all constan to uperrcase http://solidity.readthedocs.io/en/develop/style-guide.html
  uint public constant stage1end = 1525651200;
  uint public constant stage2end = 1526256000;
  uint public constant stage3end = 1526860800;
  uint public constant stage1price = 55;
  uint public constant stage2price = 60;
  uint public constant stage3price = 65;
  uint public constant stage4price = 70;
  //R all to constant!
  uint public stage1Supply = 10000000;
  uint public stage2Supply = 20000000;
  uint public stage3Supply = 30000000;
  uint public stage4Supply = 30000000;

  //R all to one naming format - startTime == stage1start; endTime == stage4end
  uint public startTime = 1525132800;
  uint public endTime = 1527379200;

}
