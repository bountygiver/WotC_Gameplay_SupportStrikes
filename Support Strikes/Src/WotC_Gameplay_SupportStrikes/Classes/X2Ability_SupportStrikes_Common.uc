class X2Ability_SupportStrikes_Common extends X2Ability config (GameData);

struct MatineeFireInfo
{
	var string	Prefix;
	var float	FireTime;
};

var config string HexColor_Good;
var config string HexColor_Caution;
var config string HexColor_Bad;

var config array<MatineeFireInfo> A10_MatineeCommentPrefixes;

static function bool TypicalSupportStrike_AlternateFriendlyName(out string AlternateDescription, XComGameState_Ability AbilityState, StateObjectReference TargetRef)
{
	local string								FriendlyName, FinalHexClr;
	local int									IntelCost, IntelHQ;
	local XComGameStateHistory					History;
	local XComGameState_HeadquartersXCom		XComHQ;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;

	// Get the original friendly name from the AbilityState that was sent in
	FriendlyName = AbilityState.GetMyTemplate().LocFriendlyName;

	// Stop here if we're in tactical since the next part requires the player be in a campaign
	if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true))
		return false;

	History = `XCOMHISTORY;

	//Grab XCom HQ
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	IntelHQ = XComHQ.GetIntel();

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	IntelCost = SupportStrikeMgr.CalculateStrikeCost_Simple(AbilityState.GetMyTemplateName());

	FinalHexClr = default.HexColor_Good;

	// If the player does not have enough intel for the support strike, use red
	if ( IntelHQ < IntelCost )
		FinalHexClr = default.HexColor_Bad;
	// If using the support strike reduces the intel cost to below the current cost, mark it yellow
	else if ( ( IntelHQ - SupportStrikeMgr.CalculateStrikeCost_Simple(AbilityState.GetMyTemplateName(),,1) ) < IntelCost )
		FinalHexClr = default.HexColor_Caution;

	//Create the string
	AlternateDescription = "[<font color='#" $ Caps(FinalHexClr) $ "'><b>" $ string(IntelCost) $ "</b></font>" $ "/" $ "<font color='#" $ Caps(FinalHexClr) $ "'><b>" $ string(IntelHQ) $ "</b></font>] " $ FriendlyName;
	return true;
}

//
// Modify the Support Strike Gamestate so we can enable Vague Orders on XCom's side
// 
simulated function XComGameState TypicalSupportStrike_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory					History;
	local XComGameState_HeadquartersXCom		XComHQ;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;
	local XComGameState							NewGameState;
	local XComGameStateContext_Ability			AbilityContext;
	local XComGameState_Ability					AbilityState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	//Do all the normal effect processing
	NewGameState = TypicalAbility_BuildGameState(Context);

	// Stop here if we're in tactical since the next part requires the player be in a campaign
	if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true))
		return NewGameState;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if (SupportStrikeMgr == none) // We're in a place that Support Strikes doesn't exist, exit the function
		return NewGameState;

	AbilityContext = XComGameStateContext_Ability(Context);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.PayStrategyCost(NewGameState, SupportStrikeMgr.CalculateStrikeCost_StrategyCost(AbilityState.GetMyTemplateName()), XComHQ.OTSUnlockScalars, XComHQ.GTSPercentDiscount);

	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	// Modify usage
	SupportStrikeMgr.AdjustStrikeUsage(AbilityState.GetMyTemplateName());

	//Return the game state we have created
	return NewGameState;
}
