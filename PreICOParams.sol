pragma solidity ^0.4.19;
contract PreICOParams {
  //R all constan to uperrcase http://solidity.readthedocs.io/en/develop/style-guide.html
  uint public constant stage1end = 1523318400;
  uint public constant stage2end = 1523923200;
  uint public constant stage3end = 1524528000;
  uint public constant stage1price = 44;
  uint public constant stage2price = 47;
  uint public constant stage3price = 50;
  uint public constant stage4price = 52;
  //R all to constant
  uint public stage1Supply = 10000000;
  uint public stage2Supply = 10000000;
  uint public stage3Supply = 10000000;
  uint public stage4Supply = 10000000;

  //R all to one naming format - startTime == stage1start; endTime == stage4end
  uint public startTime = 1522713600;
  uint public endTime = 1525046400;

}
