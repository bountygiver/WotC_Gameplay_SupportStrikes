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
	local int									IntelCost, IntelHQ, CurrentUsageIdx;
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
	CurrentUsageIdx = SupportStrikeMgr.GetCurrentStrikeUsage(AbilityState.GetMyTemplateName());

	IntelCost = SupportStrikeMgr.CalculateStrikeCost_Simple(AbilityState.GetMyTemplateName());
	`LOG("Current Intel Cost: " $ IntelCost $ ", Current Usage: " $ SupportStrikeMgr.StrikeCurrentMonthUsage[CurrentUsageIdx].Usage, true, 'WotC_Gameplay_SupportStrikes');

	FinalHexClr = default.HexColor_Good;

	// If the player does not have enough intel for the support strike, use red
	if ( IntelHQ < IntelCost )
		FinalHexClr = default.HexColor_Bad;
	// If the player uses this support strike, and the result cost ends up below this current cost, mark it yellow
	else if ( ( IntelHQ - SupportStrikeMgr.CalculateStrikeCost_Simple(AbilityState.GetMyTemplateName(),,  SupportStrikeMgr.StrikeCurrentMonthUsage[CurrentUsageIdx].Usage + 1) ) < IntelCost )
		FinalHexClr = default.HexColor_Caution;

	//Create the string
	AlternateDescription = "[<font color='#" $ Caps(FinalHexClr) $ "'><b>" $ string(IntelCost) $ "</b></font>" $ "/" $ "<font color='#" $ Caps(FinalHexClr) $ "'><b>" $ string(IntelHQ) $ "</b></font>] " $ FriendlyName;
	return true;
}

//
// Modify the Support Strike Gamestate so we can enable Vague Orders on XCom's side
// 
static function XComGameState TypicalSupportStrike_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory					History;
	local XComGameState_HeadquartersXCom		XComHQ;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;
	local XComGameState							NewGameState;
	local XComGameStateContext_Ability			AbilityContext;
	local XComGameState_Ability					AbilityState;

	//Do all the normal effect processing
	NewGameState = TypicalAbility_BuildGameState(Context);

	// Stop here if we're in tactical since the next part requires the player be in a campaign
	if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true))
		return NewGameState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

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

static function X2AbilityTrigger_EventListener CreateFixScatterZLevelEventListener()
{
	local X2AbilityTrigger_EventListener		ScatterFixEventListener;

	ScatterFixEventListener = new class'X2AbilityTrigger_EventListener';
	ScatterFixEventListener.ListenerData.Deferral	= ELD_Immediate;
	ScatterFixEventListener.ListenerData.EventID	= 'PostModifyNewAbilityContext';
	ScatterFixEventListener.ListenerData.Filter		= eFilter_None;	//	other filters don't work with effect-triggered event.
	ScatterFixEventListener.ListenerData.EventFn	= static.FixScatterZLevel;
	ScatterFixEventListener.ListenerData.Priority	= 40;

	return ScatterFixEventListener;
}

// Fixes Iridar's scatter mod to not take into account the Z-level, resulting in airburst explosives that do nothing!
// Priority must be lower than 50 to modify the scatter mechanic
static function EventListenerReturn FixScatterZLevel(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability	NewContext;
	local XComGameState_Ability			AbilityState;
	local int							i;
	local vector						IterVector;
	local AvailableTarget				Target;

	NewContext = XComGameStateContext_Ability(EventData);
	AbilityState = XComGameState_Ability(CallbackData);

	if ( NewContext.InputContext.AbilityTemplateName == AbilityState.GetMyTemplateName() )
	{
		foreach NewContext.InputContext.TargetLocations(IterVector, i)
		{
			NewContext.InputContext.TargetLocations[i].z = `XWORLD.GetFloorZForPosition(IterVector);

			// If this was a multitarget ability, we'll need to gather the targets again
			AbilityState.GatherAdditionalAbilityTargetsForLocation(NewContext.InputContext.TargetLocations[i], Target);
		}

		NewContext.InputContext.MultiTargets = Target.AdditionalTargets;
	}
	
	return ELR_NoInterrupt;
}