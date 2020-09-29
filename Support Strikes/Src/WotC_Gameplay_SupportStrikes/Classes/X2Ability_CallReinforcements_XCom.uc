//---------------------------------------------------------------------------------------
// FILE:	X2Ability_CallReinforcements_XCom.uc
// AUTHOR:	E3245
// DESC:	Ability that calls reinforcements for XCom after a delay
//
//---------------------------------------------------------------------------------------
class X2Ability_CallReinforcements_XCom extends X2Ability_SupportStrikes_Common
	config(GameData_SupportStrikes);

var localized string CallingReinforcementsFriendlyName;
var localized string CallingReinforcementsFriendlyDesc;

var config int HeliDropIn_Local_Cooldown;				//
var config int HeliDropIn_Global_Cooldown;				//
var config int HeliDropIn_Delay_Turns;					// Number of turns before the next ability will fire
var config int HeliDropIn_LostSpawnIncreasePerUse;		// Increases the number of lost per usage (Stage 2 only)
var config bool HeliDropIn_BreaksConcealment;			// Whether or not this ability will break concealment (Stage 2 only)
var config int HeliDropIn_CastRange;					// 
var config bool HeliDropIn_SquadSightRange;				// 

var name HeliDropIn_Stage2AbilityName;
var name HeliDropIn_Stage2TriggerName;
var name HeliDropIn_Stage1EffectName;

/// <summary>
/// Creates the set of abilities that implement the concealment / alertness mechanic
/// </summary>
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateSupport_Air_Defensive_HeliDropIn_T1_Stage1());
	Templates.AddItem(CreateSupport_Air_Defensive_HeliDropIn_T1_Stage2());

	return Templates;
}

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Air_Defensive_HeliDropIn_T1_Stage1()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal_All	Cooldown;
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Effect_IRI_DelayedAbilityActivation DelayEffect_HeliDropIn;
	local X2Condition_Visibility				VisibilityCondition;
	local X2Effect_SpawnAOEIndicator			FXEffect;
	local X2AbilityCost_SharedCharges			AmmoCost;
	local X2Condition_MapCheck					MapCheck;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Def_HeliDropIn_Stage1');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_platform_stability"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Always;

	//The weapon template has the actual amount of ammo
	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Ammo Cost
	AmmoCost = new class'X2AbilityCost_SharedCharges';	
    AmmoCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

//	Charges = new class'X2AbilityCharges';
//	Charges.InitialCharges = 2;
//	Template.AbilityCharges = Charges;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	Template.TargetingMethod = class'X2TargetingMethod_VoidRift';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';	//	this is just to show an approximation of potential drop positions
	MultiTarget.fTargetRadius = 2.5;						//	actual targeting logic happens in X2Effect_IRI_SpawnSoldier:GetSpawnLocation
	MultiTarget.bIgnoreBlockingCover = false; 
	Template.AbilityMultiTargetStyle = MultiTarget;

	CursorTarget = new class'X2AbilityTarget_Cursor';
//	CursorTarget.FixedAbilityRange = default.HeliDropIn_CastRange;
//	CursorTarget.bRestrictToSquadsightRange = default.HeliDropIn_SquadSightRange;
	Template.AbilityTargetStyle = CursorTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Ability Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal_All';
	Cooldown.iNumTurns = default.HeliDropIn_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.HeliDropIn_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	DelayEffect_HeliDropIn = new class 'X2Effect_IRI_DelayedAbilityActivation';
	DelayEffect_HeliDropIn.BuildPersistentEffect(default.HeliDropIn_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	DelayEffect_HeliDropIn.EffectName = 'HeloDropInStage2';
	DelayEffect_HeliDropIn.TriggerEventName = default.HeliDropIn_Stage2TriggerName;
	DelayEffect_HeliDropIn.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayEffect_HeliDropIn);

	//  Spawn the spinny circle doodad
	FXEffect = new class'X2Effect_SpawnAOEIndicator';
	FXEffect.BuildPersistentEffect(default.HeliDropIn_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	FXEffect.OverrideVFXPath = "XV_SupportStrike_ParticleSystems.ParticleSystems.P_Evac_Zone_Flare_Ring_Green";
	Template.AddShooterEffect(FXEffect);

	Template.BuildNewGameStateFn = TypicalSupportStrike_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.AlternateFriendlyNameFn = TypicalSupportStrike_AlternateFriendlyName;
	
	return Template;
}

static function X2AbilityTemplate CreateSupport_Air_Defensive_HeliDropIn_T1_Stage2()
{
	local X2AbilityTemplate					Template;
	local X2Effect_SpawnSquad				SpawnSoldierEffect;
	local X2AbilityTrigger_EventListener	DelayedEventListener;
	local X2AbilityMultiTarget_Radius		MultiTarget;
//	local X2Effect_RemoveEffects			RemoveEffects;
	local X2AbilityTarget_Cursor			CursorTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.HeliDropIn_Stage2AbilityName);

	Template.IconImage = "img:///JetPacks.UI.CallReinforcements";
	Template.AbilitySourceName = 'eAbilitySource_Default';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.RELOAD_PRIORITY+1;

	Template.AbilityToHitCalc = default.DeadEye;

	Template.bRecordValidTiles = true;

	MultiTarget = new class'X2AbilityMultiTarget_Radius';	//	this is just to show an approximation of potential drop positions
	MultiTarget.fTargetRadius = 2.5;						//	We will need this to access a native function to gather tiles for positions
	MultiTarget.bIgnoreBlockingCover = false; 
	Template.AbilityMultiTargetStyle = MultiTarget;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	// Permanently spawn a squad in the area
	SpawnSoldierEffect = new class'X2Effect_SpawnSquad';
	SpawnSoldierEffect.MaxSoldiers = 4;
	SpawnSoldierEffect.MaxPilots = 2;
	SpawnSoldierEffect.bSpawnCosmeticSoldiers = true;
	SpawnSoldierEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(SpawnSoldierEffect);

	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.HeliDropIn_Stage2TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = HeliDropIn_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	Template.BuildNewGameStateFn = CallReinforcements_BuildGameState;
	Template.BuildVisualizationFn = CallReinforcements_BuildVisualization;
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = default.HeliDropIn_LostSpawnIncreasePerUse;

	if(default.HeliDropIn_BreaksConcealment)
	{
		Template.ConcealmentRule = eConceal_Never;	//	always break concealment
		Template.SuperConcealmentLoss = 100;
	}
	else
	{
		Template.ConcealmentRule = eConceal_Always;
		Template.SuperConcealmentLoss = 0;
	}
	return Template;
}

//
// Once again borrowed from Mortar Strikes
//
static function EventListenerReturn HeliDropIn_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit					SourceUnit;
	local ApplyEffectParametersObject			AEPObject;
	local XComGameState_Ability					MortarAbilityState;
	local GameRulesCache_Unit					UnitCache;
	local int									i, j;

	SourceUnit = XComGameState_Unit(EventData);
	AEPObject = ApplyEffectParametersObject(EventSource);
	MortarAbilityState = XComGameState_Ability(CallbackData);

	`LOG("Heli Drop In triggerred. SourceUnit unit: " @ SourceUnit.GetFullName() @ "AEPObject:" @ AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName @ AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] @ MortarAbilityState.GetMyTemplateName(),, 'WotC_Gameplay_SupportStrikes');
	
	if (SourceUnit == none || AEPObject == none || MortarAbilityState == none)
    {
		`LOG("[HeliDropIn_Listener()] Something wrong, exiting.",, 'WotC_Gameplay_SupportStrikes');
        return ELR_NoInterrupt;
    }
	if (MortarAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("[HeliDropIn_Listener()] Ability belongs to another unit, exiting.",, 'WotC_Gameplay_SupportStrikes');
		return ELR_NoInterrupt;
	}
	//HistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	//	Attempt to activate ability this many times
	for (j = 0; j < 1; j++)
	{
		if (`TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache))	//we get UnitCache for the soldier that triggered this event
		{
			for (i = 0; i < UnitCache.AvailableActions.Length; ++i)	//then in all actions available to them
			{
				if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == MortarAbilityState.ObjectID)	//we find our Mortar Stage 2 ability
				{
					`LOG("[HeliDropIn_Listener()] Found Stage 2 ability.",, 'WotC_Gameplay_SupportStrikes');
					if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it succeeds all shooter conditions
					{
						// SPT_BeforeParallel - makes projectiles drop all at once, but bad viz
						if (class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],, AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations,,,, /*HistoryIndex*/,, /*SPT_BeforeParallel*/))
						{
							`LOG("[HeliDropIn_Listener()] FIRE!",, 'WotC_Gameplay_SupportStrikes');
						}
						else
						{
							`LOG("[HeliDropIn_Listener()] Could not activate ability.",, 'WotC_Gameplay_SupportStrikes');
						}
					}
					else
					{
						`LOG("[HeliDropIn_Listener()] It cannot be activated currently!",, 'WotC_Gameplay_SupportStrikes');
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

//
// Modify the Support Strike Gamestate so we can enable Vague Orders on XCom's side
// 
simulated function XComGameState CallReinforcements_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory					History;
	local XComGameState_SupportStrikeManager	SupportStrikeMgr;
	local XComGameState							NewGameState;

	History = `XCOMHISTORY;

	//Do all the normal effect processing
	NewGameState = TypicalAbility_BuildGameState(Context);

	// Stop here if we're in tactical since the next part requires the player be in a campaign
	if (class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true))
		return NewGameState;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if (SupportStrikeMgr == none) // We're in a place that Support Strikes doesn't exist, exit the function
		return NewGameState;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	// We need to enable Vague Orders on XCom's side now that heli reinforcements are in
	if (!SupportStrikeMgr.bEnableVagueOrders)
	{
		SupportStrikeMgr.bEnableVagueOrders = true;
		`LOG("[CallReinforcements_BuildGameState()] Vague Orders Enabled." ,,'WotC_Gameplay_SupportStrikes');
	}

	//Return the game state we have created
	return NewGameState;
}

simulated function CallReinforcements_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability	Context;
	local StateObjectReference			SourceUnitRef;
	//local array<StateObjectReference>	ExcludedRefs;
	local VisualizationActionMetadata	EmptyMetadata;
	local VisualizationActionMetadata	SourceUnitMetadata, SpawnedUnitMetadata;
	local XComGameState_Unit			SourceUnitState, SpawnedUnit;
	local UnitValue						SpawnedUnitValue;
	local X2Effect_SpawnSquad			SpawnSoldierEffect;
	local X2Action_CameraLookAt			LookAtAction;
	local X2Action_WaitForAbilityEffect	WaitForEffectAction;
	local X2Action_Matinee_LittleBird	MatineeAction;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local int							i;
	local array<X2Action>				LeafNodes;
	local X2Action_UpdateFOW			FOWAction;
	local Rotator						NewRot;

	//`LOG("Calling Dynamic Deployment Build Viz function", bLog, 'IRIDAR');

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	SourceUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization tree for the ability caster
	//****************************************************************************************
	SourceUnitMetadata = EmptyMetadata;
	SourceUnitMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceUnitMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(SourceUnitRef.ObjectID);
	SourceUnitMetadata.VisualizeActor = History.GetVisualizer(SourceUnitRef.ObjectID);

	//class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceUnitMetadata, Context);
	//FireAction = X2Action_Fire(class'X2Action_Fire'.static.AddToVisualizationTree(SourceUnitMetadata, Context));
	//EnterCoverAction = X2Action_EnterCover(class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceUnitMetadata, Context));

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(SourceUnitMetadata, Context));
	LookAtAction.LookAtLocation = Context.InputContext.TargetLocations[0];

	WaitForEffectAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(SourceUnitMetadata, Context, false, LookAtAction));

	//While the above happens, we should gather the units that we will play in our Matinee

	// Configure the visualization tree for the spawned soldier
	//******************************************************************************************
	SourceUnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(SourceUnitRef.ObjectID));

	// Must only have one target effect or else the viz below won't work
	SpawnSoldierEffect = X2Effect_SpawnSquad(Context.ResultContext.ShooterEffectResults.Effects[0]);
	if( SpawnSoldierEffect == none )
	{
		`RedScreenOnce("CallReinforcements_BuildVisualization: Missing X2Effect_SpawnSquad");
		`LOG("["$ GetFuncName() $"] Missing X2Effect_SpawnSquad!" ,,'WotC_Gameplay_SupportStrikes');
		return;
	}


	//	in this cycle we go through non-zero Unit Values on the ability caster
	//	these unit values contain the References to the units we need to visualize spawn for
	i = 0;

	SourceUnitState.GetUnitValue(name(class'X2Effect_SpawnSquad'.default.SpawnedUnitValueName $ i), SpawnedUnitValue);

	if (SpawnedUnitValue.fValue == 0)
		`LOG("[CallReinforcements_BuildVisualization()] No Units to spawn!" ,,'WotC_Gameplay_SupportStrikes');

	// This area is a huge performance hit / hotspot if the units' archetypes are not preloaded in some fashion
	// Spawn all of the units that are tied to the source unit
	while (SpawnedUnitValue.fValue != 0)
	{
		SpawnedUnitMetadata = EmptyMetadata;
		SpawnedUnitMetadata.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		SpawnedUnitMetadata.StateObject_NewState = SpawnedUnitMetadata.StateObject_OldState;
		SpawnedUnit = XComGameState_Unit(SpawnedUnitMetadata.StateObject_NewState);

		//Initialize the visualizer for the unit first
		SpawnSoldierEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, SpawnedUnitMetadata, SourceUnitState, SourceUnitMetadata);

		//Assign them to the metadata
		SpawnedUnitMetadata.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

		//ExcludedRefs.AddItem(SpawnedUnit.GetReference());
		//	after the unit's spawn was visualized, we zero out the Unit Value on the ability caster 
		//	to make sure this unit will not be spawned again if the ability is reactivated in the same turn
		SourceUnitState.SetUnitFloatValue(name(class'X2Effect_SpawnSquad'.default.SpawnedUnitValueName $ i), 0, eCleanup_BeginTurn);

		i++;
		SpawnedUnitValue.fValue = 0;	//	zero out the local Unit Value because if we try to get a unit value that does not exist on the target, the previous value is not overwritten by zero
										//	basically, without this step this cycle ALWAYS goes into infinite loop
		SourceUnitState.GetUnitValue(name(class'X2Effect_SpawnSquad'.default.SpawnedUnitValueName $ i), SpawnedUnitValue);
	}
	
	`LOG("[" $ GetFuncName() $ "] Actor Index count: " $ i ,, 'WotC_Gameplay_SupportStrikes');


	// Sync up here because we need to wait until all units have spawned in before proceeding with the Matinee
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	//Perform Matinee
	MatineeAction = X2Action_Matinee_LittleBird(class'X2Action_Matinee_LittleBird'.static.AddToVisualizationTree(SpawnedUnitMetadata, Context, false, none, LeafNodes));
	// Record the caster so that it doesn't add them to the Matinee by accident
	MatineeAction.SourceUnitID = SourceUnitState.ObjectID;

	//Recalculate Rotator. We only want the Yaw
	NewRot = Rotator(Context.InputContext.TargetLocations[0]);
	NewRot.Pitch = 0;
	NewRot.Roll = 0;

	MatineeAction.SetMatineeLocation(Context.InputContext.TargetLocations[0], NewRot);
	MatineeAction.PostMatineeUnitVisibility = PostMatineeVisibility_Visible;

	//Add a join so that all hit reactions and other actions will complete before the visualization sequence moves on. In the case
	// of fire but no enter cover then we need to make sure to wait for the fire since it isn't a leaf node
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	//Perform FOW updates, if any
	FOWAction = X2Action_UpdateFOW( class'X2Action_UpdateFOW'.static.AddToVisualizationTree(SpawnedUnitMetadata, Context, false, SpawnedUnitMetadata.LastActionAdded));
	FOWAction.ForceUpdate = true;

}

defaultproperties
{
	HeliDropIn_Stage2AbilityName="Ability_Support_Air_Def_HeliDropIn_Stage2"
	HeliDropIn_Stage2TriggerName="Trigger_Support_Air_Def_HeliDropIn_Stage2"
	HeliDropIn_Stage1EffectName="Effect_Support_Air_Def_HeliDropIn_Stage1"
}