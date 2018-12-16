pragma solidity = 0.4.25;
import 'https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/math/SafeMath.sol';

contract own{
  address public owner;
  
  constructor() public{
    owner = msg.sender;
  }
  
  modifier onlyOwnerOf {
    require(msg.sender == owner);
    _;
  }
}

contract erc721{  
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


contract game is erc721, own{
    using SafeMath for uint;
    using SafeMath for uint32;
    using SafeMath for uint256;
    
    struct player{
     address uuid;
        uint lastClaimReward;
        uint troops;
        uint[] ownDomain;
        uint ownDomainNum;
    }
    
    struct domain{
        address owner; //領地擁有者
        uint8 level;  //領地等級(等級越高產出越高)
        uint troops; //領地駐守兵力
        uint lastClaimReward;
    }
    
    domain[50000] public domains;
    mapping (address => player) public players;

    event AttackDomain(address indexed atk, uint indexed _id, bool sucess);
    event Deploy(address indexed deployer,uint domain,uint amout);
    event GetTroop(address indexed, uint troop);
    
    uint every_cooltime = 86400;
    uint reset = 0;
    uint troopPerLevelGive = 30;
    uint conversionRatio = 100000000000000000; // 1 to 10 troops
    uint dailyTroopsGiven = 100;
    
    //player players[msg.sender] = players[msg.sender];
    
    /*
	attribute above
	method below
    */
    
    function view_user_cooldown(address _player)view public returns(uint){
        uint returning_cd = players[_player].lastClaimReward + every_cooltime - now;
        return returning_cd;
    }
    
    function view_domain_cooldown(uint _domain)view public returns(uint){
        uint returning_cd = domains[_domain].lastClaimReward + every_cooltime - now;
        return returning_cd;
    }
    
    function upgrade(uint _domain,uint _level) public payable{
        domains[_domain].level += uint8(_level);
    }
    
    function retrieveDomain(uint index) private view returns(domain){
        return domains[index];
    }
    
    function attackDomain(uint _atk_roops, uint _attackedDomain)public {
        require(_atk_roops<= players[msg.sender].troops);
        if(_atk_roops >= domains[_attackedDomain].troops ){
            // 所攻擊的領地打得下來
            domains[_attackedDomain].troops = reset;
            players[msg.sender].troops -= _atk_roops;
            
            domains[_attackedDomain].owner = msg.sender;
            domains[_attackedDomain].troops = _atk_roops - domains[_attackedDomain].troops;
            players[msg.sender].ownDomain.push(_attackedDomain);
            players[msg.sender].ownDomainNum++;
            
            emit AttackDomain(msg.sender,_attackedDomain,true);
        }else{ //打不下來
            players[msg.sender].troops = reset;
            domains[_attackedDomain].troops -= players[msg.sender].troops;
            emit AttackDomain(msg.sender,_attackedDomain,false);
        }    
    }
    
    function buyTroops() payable public returns(bool){
        uint givingTroops = msg.value / conversionRatio;
        players[msg.sender].troops += givingTroops;
    }
    
    function dailyReward() public {
        require(players[msg.sender].lastClaimReward + every_cooltime <= now);
        
        players[msg.sender].troops += dailyTroopsGiven;
        players[msg.sender].lastClaimReward = now;
        emit GetTroop(msg.sender, dailyTroopsGiven);
    }
    
    function deployTroops(uint deploying, uint troopsNum) public returns(string){
        require(players[msg.sender].troops >= troopsNum);
        
        domains[deploying].troops += troopsNum;
        players[msg.sender].troops -= troopsNum;
        emit Deploy(msg.sender, deploying, troopsNum);
    }
    
    function recall_troops(uint _domain, uint troopsNum) public returns(string){
        require(players[msg.sender].troops >= troopsNum);
        
        domains[_domain].troops += troopsNum;
        players[msg.sender].troops -= troopsNum;
        emit Deploy(msg.sender, _domain, troopsNum);
    }
    
    
    function claimADomainReward(uint Domain) public {
        
        require(domains[Domain].lastClaimReward + every_cooltime <= now);
        players[msg.sender].troops += domains[Domain].level * troopPerLevelGive;
        domains[Domain].lastClaimReward = now;
    }
    
    
    function claimAllDomainReward()  private{
     for(uint i = reset; i < players[msg.sender].ownDomain.length; i++){
         claimADomainReward(players[msg.sender].ownDomain[i]);
     }
    }
  
  /*
  under this section is erc protocol
  */

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    players[_to].ownDomainNum++;
    players[_from].ownDomainNum--;
    domains[_tokenId].owner = _to;
    
    emit Transfer(_from, _to, _tokenId);
  } //領地交換協定

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf() {
    _transfer(msg.sender, _to, _tokenId);
  }//交換函數

  mapping (uint => address) domainapproval;
  
  function approve (address _to, uint256 _tokenId) public onlyOwnerOf() {
    domainapproval[_tokenId] = _to;
    emit Approval( msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require( domainapproval[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
  
  function balanceOf(address _owner) public view returns (uint256 _balance){
      return players[_owner].ownDomainNum;
  }
  
  function ownerOf(uint256 _tokenId) public view returns (address _owner){
      return domains[_tokenId].owner;
  }
  
  function view_troops(address _address) view public returns(uint){
      return players[_address].troops;
  }
  
}
