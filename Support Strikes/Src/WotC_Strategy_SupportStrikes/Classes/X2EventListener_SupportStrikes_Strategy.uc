//
// FILE: X2EventListener_SupportStrikes.uc
// DESC: Strategic Event Listeners that don't belong elsewhere
//
class X2EventListener_SupportStrikes_Strategy extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupportStrikeStrategyListeners());

	return Templates;
}

static function CHEventListenerTemplate CreateSupportStrikeStrategyListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'SupportStrike_StrategicListener');
	Template.AddCHEvent('OnViewStrategyPolicies', OnViewStrategyPolicies, ELD_OnStateSubmitted, 50);
	Template.RegisterInStrategy = true;

	return Template;
}


//
// At the end of the month, restore the original intel cost for the support strikes
//
static function EventListenerReturn OnViewStrategyPolicies(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory					History;
	local XComGameState_HeadquartersXCom		XComHQ;
	local XComGameState							NewGameState;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Create a new gamestate since something will be modified
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2EventListener_SupportStrikes.OnTacticalBeginPlay");

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	//Reset costs back to original values
	SupportStrikeMgr.CurrentMonthAbilityIntelCost = SupportStrikeMgr.ScaledSupportStrikeCosts;

	// If something happened, submit gamestate
	// Otherwise, clean up the gamestate
	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`LOG("[OnViewStrategyPolicies()] Submitted changes to history." ,,'WotC_Gameplay_SupportStrikes');
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}