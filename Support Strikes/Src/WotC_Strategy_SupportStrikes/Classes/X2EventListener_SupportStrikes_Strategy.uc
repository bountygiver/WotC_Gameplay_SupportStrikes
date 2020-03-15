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
	local XComGameStateHistory				History;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState						NewGameState;
	local XComGameState_FacilityXCom		FacilityState;
	local X2StrategyElementTemplateManager	TemplateMan;
	local X2SoldierUnlockTemplate			UnlockTemplate;
	local name								UnlockName;
	local int								Value;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Create a new gamestate since something will be modified
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2EventListener_SupportStrikes.OnTacticalBeginPlay");

	FacilityState = XComHQ.GetFacilityByName('OfficerTrainingSchool');
	FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
	TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	foreach FacilityState.GetMyTemplate().SoldierUnlockTemplates(UnlockName)
	{
		//
		// TODO: Better implementation
		//
		if	( UnlockName == 'GTSUnlock_Artillery_Off_MortartStrike_HE_T1' ||
			   UnlockName == 'GTSUnlock_Artillery_Def_MortartStrike_SMK_T1' ||
			   UnlockName == 'GTSUnlock_Orbital_Off_IonCannon_T1'
			)
		{
			Value = XComHQ.GetGenericKeyValue(string(UnlockName));
			if (Value != -1)
			{
				UnlockTemplate = X2SoldierUnlockTemplate(TemplateMan.FindStrategyElementTemplate(UnlockName));
				UnlockTemplate.Cost.ResourceCosts[0].Quantity = Value;
				`LOG("[OnViewStrategyPolicies()] Returning " $ string(UnlockName) $ "'s " $ UnlockTemplate.Cost.ResourceCosts[0].ItemTemplateName $ " cost back to QTY: " $ UnlockTemplate.Cost.ResourceCosts[0].Quantity,,'WotC_Gameplay_SupportStrikes');
			}
		}
	}

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