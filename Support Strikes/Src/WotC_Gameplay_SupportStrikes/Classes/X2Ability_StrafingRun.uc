class X2Ability_StrafingRun extends X2Ability_SupportStrikes_Common
	config(GameData_SupportStrikes);

var config int StrafingRun_A10_Init_Local_Cooldown;		// Used as part of the init ability to summon the A10
var config int StrafingRun_A10_Init_Global_Cooldown;	//

var config int StrafingRun_A10_Strike_Local_Cooldown;	// Used when the A10 is in the AO. Allows the player to strike locations n at a time.
var config int StrafingRun_A10_Strike_Global_Cooldown;	//

var config int StrafingRun_A10_Init_Delay_Turns;		// Number of turns before the support strike arrives
var config int StrafingRun_A10_Strike_Delay_Turns;		// Number of turns before the strike happens
var config int StrafingRun_A10_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config bool StrafingRun_A10_Panic_Enable;
var config int StrafingRun_A10_Panic_NumOfTurns;

var config int StrafingRun_A10_TileWidth;
var config int StrafingRun_A10_Range;

var config bool StrafingRun_A10_Disorient_Enable;
var config int StrafingRun_A10_Disorient_NumOfTurns;

var config array<string> StrafingRun_A10_Stage4_AbilityCamera;

var config int StrafingRun_A10_SupportDuration;			// How long this support strike is available once in the AO

var name StrafingRun_A10_Stage1_DirSlcTriggerName;
var name StrafingRun_A10_Stage1_DirSlcAbilityName;
var name StrafingRun_A10_Stage1_LocSelectEffectName;

var name StrafingRun_A10_Stage2_FinalTriggerName;
var name StrafingRun_A10_Stage3_EffectName;
var name StrafingRun_A10_Stage3_FinalAbilityName;
var name StrafingRun_A10_Stage4_FinalAbilityName;
var name StrafingRun_A10_Stage4_FinalTriggerName;



// 9/27/21:
// Per Beagle, Air Support Strikes (Strafing Run, Carpet Bomb, Precision Guided Bombs, whatever else) will now take N turns to arrive (Stage1 to Stage2)
// Stage2 grants XCom use of Support Strikes (Stage3). The player can then call in strikes (Stage3) to destroy whatever (Stage4)
// 
// Stage1 (Call it in) -> Stage2 (Available for Tasking) -> Stage3 (Place Support Marker) -> Stage4 (KABOOM!)

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage1());	//Call in the plane to the AO
	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage2());	// Grants authorization

	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage3_InitLocation());	// Place a strike in the area
	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage3_SelectAngle());	// Place a strike in the area
	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage4());				// KABOOM

	Templates.AddItem(CreateDummyTarget_Initialize());

	return Templates;
}


//
// STRAFING RUN
//

/*
	 How this ability is set up:
	 1) The user picks a target location
	 2) The user picks the target direction
	 3) PROFIT!
*/

static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage1()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal_All	Cooldown;
	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
//	local X2AbilityCost_Ammo					AmmoCost;
	local X2Condition_MapCheck					MapCheck;
	local X2Effect_DelayedAbilityActivation		DelayEffect_StrafingRun;
	local X2Condition_UnitEffects				UnitEffects;
	local X2Condition_AbilityCharges			AbilityChargesCondition;
	local X2Condition_CS_UnitType				DummyTargetUnitCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_A10_Stage1');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	// Hide if the A10 is here in the AO (Stage 3 is active)
	Template.HideErrors.AddItem('AA_AbilityUnavailableIfA10AtStage2');
		
	//This version does not consume ammo, but if the weapon is out of ammo, then the strike is disabled
//	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Always;

	//	Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal_All';
	Cooldown.iNumTurns = default.StrafingRun_A10_Init_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.StrafingRun_A10_Init_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	UnitEffects = new class'X2Condition_UnitEffects';
	UnitEffects.AddExcludeEffect(default.StrafingRun_A10_Stage3_EffectName, 'AA_AbilityUnavailableIfA10AtStage2');
	Template.AbilityShooterConditions.AddItem(UnitEffects);

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	//Exclude dead units from using this ability
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_ResourceCost');

	DummyTargetUnitCondition = new class'X2Condition_CS_UnitType';
	DummyTargetUnitCondition.ExcludeTypes.AddItem('Support_Strikes_Dummy_Target');
	DummyTargetUnitCondition.bUnitTemplateNameInsteadOfCharacterGroupName = true;
	DummyTargetUnitCondition.bCheckSource = true;
	Template.AbilityShooterConditions.AddItem(DummyTargetUnitCondition);
	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityShooterConditions.AddItem(VisibilityCondition);

	AbilityChargesCondition = new class'X2Condition_AbilityCharges';
	AbilityChargesCondition.AbilityToCheck.AddItem(default.StrafingRun_A10_Stage3_FinalAbilityName);
	AbilityChargesCondition.MinNumberOfCharges = 0;
	Template.AbilityShooterConditions.AddItem(AbilityChargesCondition);

	DelayEffect_StrafingRun = new class 'X2Effect_DelayedAbilityActivation';
	DelayEffect_StrafingRun.BuildPersistentEffect(default.StrafingRun_A10_Init_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	DelayEffect_StrafingRun.EffectName = 'A10DelayedArrivalEffect';
	DelayEffect_StrafingRun.TriggerEventName = default.StrafingRun_A10_Stage2_FinalTriggerName;
	DelayEffect_StrafingRun.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayEffect_StrafingRun);

	//Template.bSkipFireAction = true;

	Template.BuildNewGameStateFn = TypicalSupportStrike_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.AlternateFriendlyNameFn = TypicalSupportStrike_AlternateFriendlyName;

	return Template;
}

// Have this ability grant the user the ability to use 1 Turn Air Support
// This is granted to all XCom units
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage2()
{
	local X2AbilityTemplate							Template;
	local X2Effect_Persistent						Effect;
	local X2AbilityMultiTarget_AllAllies			MultiTargetingStyle;
	local X2AbilityTrigger_EventListener			EventListener;
	local X2Condition_CS_UnitType					DummyTargetUnitCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_A10_Stage2');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	MultiTargetingStyle = new class'X2AbilityMultiTarget_AllAllies';
	MultiTargetingStyle.bUseAbilitySourceAsPrimaryTarget = true;
	Template.AbilityMultiTargetStyle = MultiTargetingStyle;

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = default.StrafingRun_A10_Stage2_FinalTriggerName;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_SelfWithAdditionalTargets;	// Need to trigger on every unit possible
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	DummyTargetUnitCondition = new class'X2Condition_CS_UnitType';
	DummyTargetUnitCondition.ExcludeTypes.AddItem('Support_Strikes_Dummy_Target');
	DummyTargetUnitCondition.bUnitTemplateNameInsteadOfCharacterGroupName = true;
	DummyTargetUnitCondition.bCheckSource = true;
	Template.AbilityShooterConditions.AddItem(DummyTargetUnitCondition);

	// Simply used to visualize the support strike flyover indicator once, and soon a narrative moment
	Effect = new class'X2Effect_Persistent';
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.EffectName = 'A10Stage2ShooterVisualizationEffect';
	Effect.VisualizationFn = StrafingRun_Stage2_ShooterVisualizer;
	Template.AddShooterEffect(Effect);

	Effect = new class'X2Effect_Persistent';
	Effect.BuildPersistentEffect(default.StrafingRun_A10_SupportDuration + 1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), "UILibrary_XPACK_Common.PerkIcons.UIPerk_barrierdarkevent");
	Effect.EffectName = default.StrafingRun_A10_Stage3_EffectName;
	Template.AddTargetEffect(Effect);
	Template.AddMultiTargetEffect(Effect);

	Template.bSkipFireAction		= true;
	Template.BuildNewGameStateFn	= TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn	= TypicalAbility_BuildVisualization;

	return Template;
}

static function StrafingRun_Stage2_ShooterVisualizer(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameStateContext_Ability  AbilityContext;
	local X2AbilityTemplate 			AbilityTemplate;

	// No visualizer for misses!
	if (EffectApplyResult != 'AA_Success')
		return;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	// Prepare a dramatic flyover indicating that the strike is ready
	class'X2StatusEffects'.static.AddEffectMessageToTrack(ActionMetadata,
														  AbilityTemplate.LocFlyOverText,
														  VisualizeGameState.GetContext(),
														  "Strike Available",
														  "img:///UILibrary_StrategyImages.X2StrategyMap.MapPin_Generic",
														  eUIState_Good);
}

// Drop a unit that will become our target indicator for the strafing run
static function X2AbilityTemplate CreateSupport_Air_Offensive_StrafingRun_Stage3_InitLocation()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCooldown_LocalAndGlobal_All	Cooldown;
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_UnitEffects				A10inAORequiredCondition;
	local X2Condition_CS_UnitType				DummyTargetUnitCondition;
	local X2Condition_AbilitySourceWeapon		AmmoCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.StrafingRun_A10_Stage3_FinalAbilityName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	Template.HideErrors.AddItem('AA_MissingRequiredEffect');

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Always;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = false;
	MultiTarget.bUseWeaponRadius = false;
	MultiTarget.fTargetRadius = 1.0f;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	// Will force the ability into cooldown via script
	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal_All';
	Cooldown.ReserveNumLocalTurns 	= default.StrafingRun_A10_Strike_Local_Cooldown;
	Cooldown.ReserveNumGlobalTurns 	= default.StrafingRun_A10_Strike_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	/* BEGIN Shooter Conditions */

	//Exclude dead units from using this ability
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// This will hide the ability if not found
	A10inAORequiredCondition = new class'X2Condition_UnitEffects';
	A10inAORequiredCondition.AddRequireEffect(default.StrafingRun_A10_Stage3_EffectName, 'AA_MissingRequiredEffect');
	Template.AbilityShooterConditions.AddItem(A10inAORequiredCondition);

	DummyTargetUnitCondition = new class'X2Condition_CS_UnitType';
	DummyTargetUnitCondition.ExcludeTypes.AddItem('Support_Strikes_Dummy_Target');
	DummyTargetUnitCondition.bUnitTemplateNameInsteadOfCharacterGroupName = true;
	DummyTargetUnitCondition.bCheckSource = true;
	Template.AbilityShooterConditions.AddItem(DummyTargetUnitCondition);

	// There must be ammo left in the weapon before this ability can be used!
	AmmoCondition = new class'X2Condition_AbilitySourceWeapon';
	AmmoCondition.AddAmmoCheck(0, eCheck_GreaterThan);
	Template.AbilityShooterConditions.AddItem(AmmoCondition);
	/* END Shooter Conditions */

	// Simply used to visualize the support strike flyover indicator once, and soon a narrative moment
	// Spawn the Dummy target on the cursor location
	// Enough, let the BuildGameState handle the spawning of the unit!
//	SpawnInvisibleSectoidEffect = new class 'X2Effect_SpawnDummyTarget';
//	SpawnInvisibleSectoidEffect.BuildPersistentEffect(1, true, false);	// We will handle destruction when finished
//	SpawnInvisibleSectoidEffect.EffectName = 'A10StrafingRunSpawnIndicatorUnitEffect';
////	SpawnInvisibleSectoidEffect.bAddToSourceGroup = true; // We will need to erase the unit if needed
//	SpawnInvisibleSectoidEffect.UnitToSpawnName = 'Support_Strikes_Dummy_Target';
//	SpawnInvisibleSectoidEffect.bApplyOnHit = true;
//	SpawnInvisibleSectoidEffect.bApplyOnMiss = true;
//	Template.AddTargetEffect(SpawnInvisibleSectoidEffect);

	Template.bSkipFireAction			= true;
	Template.FrameAbilityCameraType		= eCameraFraming_Never;

	Template.BuildNewGameStateFn 		= SpawnIndicator_BuildGameState;
	Template.BuildVisualizationFn 		= SpawnIndicator_BuildVisualization;

	return Template;
}

// Triggers the ability and kills the unit that owns this ability
static function XComGameState SpawnIndicator_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory 			History;	
	local XComGameState 				NewGameState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit 			UnitState, GroupUnitState, SpawnedUnit;
	local XComGameState_AIGroup 		UnitGroup;
	local StateObjectReference			ObjRef, kNewUnit;

	local X2EventManager		EventManager;
	local Object				SelfObject;

	History = `XCOMHISTORY;	

	NewGameState = History.CreateNewGameState(true, Context);
	AbilityContext = XComGameStateContext_Ability(Context);

	// Check if we need to wipe out the inidicator unit if it already exists
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	UnitGroup = UnitState.GetGroupMemberShip(NewGameState);
	
	//`LOG("Got Source Unit [" $ UnitState.ObjectID $ "]: " $ UnitState.GetMyTemplateName() $ ", " $ UnitState.GetName(eNameType_Full), true, 'WotC_Gameplay_SupportStrikes');
		
	foreach UnitGroup.m_arrMembers(ObjRef)
	{
		GroupUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjRef.ObjectID));

		//`LOG("Checking Unit [" $ GroupUnitState.ObjectID $ "]: " $ GroupUnitState.GetMyTemplateName() $ ", " $ GroupUnitState.GetName(eNameType_Full), true, 'WotC_Gameplay_SupportStrikes');
		
		// Trigger the RemoveStateFromPlay function and event to properly remove this unit from the game
		if (GroupUnitState.GetMyTemplateName() == 'Support_Strikes_Dummy_Target') 
		{
			UnitGroup = XComGameState_AIGroup(NewGameState.ModifyStateObject(UnitGroup.Class, UnitGroup.ObjectID));
			UnitGroup.RemoveUnitFromGroup(GroupUnitState.ObjectID, NewGameState);

			GroupUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(GroupUnitState.Class, GroupUnitState.ObjectID));
			GroupUnitState.RemoveStateFromPlay();

			`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', GroupUnitState, GroupUnitState, NewGameState);
		}
	}

	kNewUnit = `SPAWNMGR.CreateUnit( AbilityContext.InputContext.TargetLocations[0], 'Support_Strikes_Dummy_Target', eTeam_XCom, false, false, NewGameState,,, false,, UnitGroup.GetReference().ObjectID);

	if (kNewUnit.ObjectID <= 0)
	{
		`RedScreenOnce(GetFuncName() $ ": 'Support_Strikes_Dummy_Target' was not created properly. This may cause the ability to break!");
		return NewGameState;
	}

	SpawnedUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(kNewUnit.ObjectID));
	SpawnedUnit.bTriggerRevealAI = false;
	
	// Track the Spawned unit
	UnitState.SetUnitFloatValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, kNewUnit.ObjectID, eCleanup_BeginTurn);

	if (UnitState.IsSquadConcealed())
		SpawnedUnit.SetIndividualConcealment(true, NewGameState); //Don't allow the mimic beacon to be non-concealed in a concealed squad.

	// Nullify any Concealment Event Listeners so it cannot reveal itself to the enemy
	SelfObject = SpawnedUnit;
	EventManager = `XEVENTMGR;
//
	EventManager.UnregisterFromEvent(SelfObject, 'ObjectMoved', ELD_OnStateSubmitted);		
	EventManager.UnregisterFromEvent(SelfObject, 'UnitMoveFinished', ELD_OnStateSubmitted);
//
//	// Better safe than sorry
	EventManager.UnregisterFromEvent(SelfObject, 'EffectBreakUnitConcealment', ELD_OnStateSubmitted);

	SpawnedUnit.bRequiresVisibilityUpdate = true;

	return NewGameState;
}

simulated function SpawnIndicator_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata SourceUnitTrack, IndicatorTrack;
	local XComGameState_Unit SourceUnit, SpawnedUnit;
	local UnitValue SpawnedUnitValue;
	local X2Action_SelectNextActiveUnitTriggerUI 	SelectUnitAction;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	SourceUnitTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(InteractingUnitRef.ObjectID,
													   SourceUnitTrack.StateObject_OldState, SourceUnitTrack.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);
	SourceUnitTrack.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	SourceUnit = XComGameState_Unit(SourceUnitTrack.StateObject_NewState);

	// Play the civilian and Faceless change form actions
	SourceUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

	IndicatorTrack = EmptyTrack;
	IndicatorTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	IndicatorTrack.StateObject_NewState = IndicatorTrack.StateObject_OldState;
	SpawnedUnit = XComGameState_Unit(IndicatorTrack.StateObject_NewState);
	IndicatorTrack.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

	// Sync up visualizer. This will unhide the unit
	class'X2Action_SyncVisualizer'.static.AddToVisualizationTree(IndicatorTrack, Context, false);
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(IndicatorTrack, Context, false, IndicatorTrack.LastActionAdded);

	// Force the Tactical Controller to switch to this unit
	SelectUnitAction = X2Action_SelectNextActiveUnitTriggerUI(class'X2Action_SelectNextActiveUnitTriggerUI'.static.AddToVisualizationTree(IndicatorTrack, Context, false, IndicatorTrack.LastActionAdded));
	SelectUnitAction.TargetID = IndicatorTrack.StateObject_NewState.ObjectID;
}


// This ability sets up the Direction and Angle of the attack, Autoselected when the player triggers the first half of the ability.
static function X2AbilityTemplate CreateSupport_Air_Offensive_StrafingRun_Stage3_SelectAngle()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Effect_SpawnAOEIndicator			StrafingRun_A10_Stage1TargetEffect;
	local X2AbilityMultiTarget_Line				LineMultiTarget;
	local X2Effect_IRI_DelayedAbilityActivation DelayEffect_StrafingRun;
	local X2Condition_CS_UnitType				DummyTargetUnitCondition;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2Effect_SpawnAOEIndicator			A10StrafingRunIndicatorEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_A10_Stage3_SelectAngle');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_juggernaut"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;	// This will always show the ability, but only the Support_Strikes_Dummy_Target unit can use it
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Always;

	// This is exclusive to one unit. No other unit can use it.
	DummyTargetUnitCondition = new class'X2Condition_CS_UnitType';
	DummyTargetUnitCondition.IncludeTypes.AddItem('Support_Strikes_Dummy_Target');
	DummyTargetUnitCondition.bUnitTemplateNameInsteadOfCharacterGroupName = true;
	DummyTargetUnitCondition.bCheckSource = true;
	Template.AbilityShooterConditions.AddItem(DummyTargetUnitCondition);

	// TODO: Will force the unit that spawned this to cost an action
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = default.StrafingRun_A10_Range;
	Template.AbilityTargetStyle = CursorTarget;

	LineMultiTarget = new class'X2AbilityMultiTarget_Line';
	LineMultiTarget.TileWidthExtension = default.StrafingRun_A10_TileWidth;
	Template.AbilityMultiTargetStyle = LineMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_Line';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	DelayEffect_StrafingRun = new class 'X2Effect_IRI_DelayedAbilityActivation';
	DelayEffect_StrafingRun.BuildPersistentEffect(default.StrafingRun_A10_Strike_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	DelayEffect_StrafingRun.EffectName = 'SR_Stage4DelayEffect';
	DelayEffect_StrafingRun.TriggerEventName = default.StrafingRun_A10_Stage4_FinalTriggerName;
	Template.AddShooterEffect(DelayEffect_StrafingRun);

	// Drop an indicator mesh on the specified angle
	// NOTE: This needs a sync visualization function so it persists on load!
	A10StrafingRunIndicatorEffect = new class'X2Effect_SpawnAOEIndicator';
	A10StrafingRunIndicatorEffect.BuildPersistentEffect(default.StrafingRun_A10_Strike_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	A10StrafingRunIndicatorEffect.OverrideVFXPath = "XV_SupportStrike_ParticleSystems.ParticleSystems.A10_StrafingRun_LineIndicator";
	A10StrafingRunIndicatorEffect.bIsLine = true;
	Template.AddShooterEffect(A10StrafingRunIndicatorEffect);

	Template.bShowActivation 		= false;
	Template.bSkipFireAction 		= true;
	Template.BuildNewGameStateFn 	= A10StrafingRun_Stage3SelectAngle_BuildGameState;
	Template.BuildVisualizationFn 	= TypicalAbility_BuildVisualization;
	
	return Template;
}

// Triggers the ability, and applys cost to certain abilities to all units
static function XComGameState A10StrafingRun_Stage3SelectAngle_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory 					History;	
	local XComGameState 						NewGameState;
	local XComGameStateContext_Ability			AbilityContext;
	local XComGameState_Unit 					UnitState;
	local XComGameState_AIGroup 				UnitGroup;
	local StateObjectReference					ObjRef, AbilityRef;
	local XComGameState_Ability					AbilityState;
	local array<name>							arrAbilityName;
	local name									AbilityName;
	local X2AbilityCooldown_LocalAndGlobal_All	Cooldown;
	local XComGameState_Item					AffectWeapon;

	History = `XCOMHISTORY;	

	// Fire the ability as normal
	NewGameState = TypicalAbility_BuildGameState(Context);
	AbilityContext = XComGameStateContext_Ability(Context);

	// Grab the firing indicator's group state
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	UnitGroup = UnitState.GetGroupMemberShip();

	arrAbilityName.AddItem(default.StrafingRun_A10_Stage3_FinalAbilityName);

	foreach UnitGroup.m_arrMembers(ObjRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjRef.ObjectID));

    	foreach arrAbilityName(AbilityName)
    	{
    	    AbilityRef = UnitState.FindAbility(AbilityName);
    	    if (AbilityRef.ObjectID > 0)
    	    {
				// Consume Charges and Ammo, if applicable
    	        AbilityState 	= XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', AbilityRef.ObjectID));
				
				if (AbilityState.iCharges > -1)
					AbilityState.iCharges 		-= 1;

				AbilityState.iAmmoConsumed 	= 1;

				AffectWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', AbilityState.GetSourceWeapon().ObjectID));
				AffectWeapon.Ammo -= 1;

				if (AbilityState.GetMyTemplate().AbilityCooldown != none)
				{
					Cooldown = X2AbilityCooldown_LocalAndGlobal_All(AbilityState.GetMyTemplate().AbilityCooldown);

					if ( Cooldown != none && (`CHEATMGR == none || !`CHEATMGR.Outer.bGodMode) )
					{
						Cooldown.ApplyCooldownExternal(AbilityState, UnitState, AbilityState.GetSourceWeapon(), NewGameState);
					}
				}
    	    }
    	}
	}

	return NewGameState;
}

//The actual ability
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage4()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		DelayedEventListener;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2Effect_ApplyWeaponDamage_Line		DamageEffect;
//	local X2AbilityMultiTarget_Radius			MultiTarget;
	//local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Line				LineMultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_PersistentStatChange			DisorientedEffect;
	local X2Effect_Panicked						PanickedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.StrafingRun_A10_Stage4_FinalAbilityName);
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.CinescriptCameraType = default.StrafingRun_A10_Stage4_AbilityCamera[0];

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;
	Template.bDontDisplayInAbilitySummary = true;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	/*
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = MultiTarget;
 	*/

	LineMultiTarget = new class'X2AbilityMultiTarget_Line';
	LineMultiTarget.TileWidthExtension = default.StrafingRun_A10_TileWidth;
	Template.AbilityMultiTargetStyle = LineMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_Line';

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = true;
	Template.AbilityToHitCalc = StandardAim;
	
	//	Multi Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
    UnitPropertyCondition.ExcludeDead = false;
    UnitPropertyCondition.ExcludeFriendlyToSource = false;
    UnitPropertyCondition.ExcludeHostileToSource = false;
    UnitPropertyCondition.FailOnNonUnits = false;
	UnitPropertyCondition.ExcludeInStasis = false;
    Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral	= ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID	= default.StrafingRun_A10_Stage4_FinalTriggerName;
	DelayedEventListener.ListenerData.Filter	= eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn	= static.StrafingRun_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage_Line';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	Template.AddMultiTargetEffect(DamageEffect);

	//	These have to be Multi Target effects, this attack has no primary target.
//	if (default.StrafingRun_A10_Panic_Enable)
//	{
//
//		//  Panic effect
//		PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
//		PanickedEffect.iNumTurns = default.StrafingRun_A10_Panic_NumOfTurns;
//		PanickedEffect.MinStatContestResult = 2;
//		PanickedEffect.MaxStatContestResult = 3;
//		Template.AddMultiTargetEffect(PanickedEffect);
//
//	}
//
//	if (default.StrafingRun_A10_Disorient_Enable)
//	{
//		//  Disorient effect
//		DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
//		DisorientedEffect.iNumTurns = default.StrafingRun_A10_Disorient_NumOfTurns;
//		DisorientedEffect.MinStatContestResult = 1;
//		DisorientedEffect.MaxStatContestResult = 1;
//		Template.AddMultiTargetEffect(DisorientedEffect);
//	}

	Template.CinescriptCameraType = "MortarStrikeFinal";
	Template.ActionFireClass = class'X2Action_Fire_StrafingRun_A10';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn 		= A10StrafingRun_BuildGameState;
	Template.BuildVisualizationFn 		= A10StrafingRun_BuildVisualization;
	Template.BuildInterruptGameStateFn	= None; // This ability cannot be interrupted
	Template.ModifyNewContextFn			= A10StrafingRun_ModifyActivatedAbilityContext;

	Template.LostSpawnIncreasePerUse = default.StrafingRun_A10_LostSpawnIncreasePerUse;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

// Need to rebuild the multiple targets in our AoE.
static function A10StrafingRun_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameStateHistory 			History;
	local X2AbilityMultiTargetStyle 	LineMultiTarget;
	local XComGameState_Ability 		AbilityState;
	local AvailableTarget 				MultiTargets;
	local vector						IterVector, LocationVector;
	local array<TTile> 					Tiles;
	local TTile		 					Tile, TempTile;
	local array<vector> 				FloorPoints;
	local XComWorldData 				WorldData;
	local array<StateObjectReference>	UnitRefs;
	local StateObjectReference 			UnitRef, ObjRef;
	local XComGameState_Unit			TileUnitState;
	local array<Actor>					TileActors;
	local Actor							TileActor;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	AbilityContext = XComGameStateContext_Ability(Context);

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));

	// Build the MultiTarget array based upon the impact points
	LineMultiTarget = AbilityState.GetMyTemplate().AbilityMultiTargetStyle;// new class'X2AbilityMultiTarget_Radius';
	foreach AbilityContext.InputContext.TargetLocations(IterVector)
	{
		LineMultiTarget.GetMultiTargetsForLocation(AbilityState, IterVector, MultiTargets);
		LineMultiTarget.GetValidTilesForLocation(AbilityState, IterVector, Tiles);
	}

//	`LOG("[" $ GetFuncName() $ "] Highest Position: (" $ HighestPosition.X $ "," $ HighestPosition.Y $ ", " $ HighestPosition.Z $ "), Lowest Position: (" $ LowestPosition.X $ "," $ LowestPosition.Y $ ", " $ LowestPosition.Z $ "), Collection Size: " $ Collection.Length $ ", Original TargetLocation Size: " $ AbilityContext.InputContext.TargetLocations.Length,,'WotC_Gameplay_SupportStrikes');
//	`LOG("[" $ GetFuncName() $ "] Collection Size: " $ Tiles.Length $ ", Original TargetLocation Size: " $ AbilityContext.InputContext.TargetLocations.Length,,'WotC_Gameplay_SupportStrikes');

	// Iterate through the tiles and find if there are floor tiles above or below us
	foreach Tiles(Tile)
	{
		LocationVector = WorldData.GetPositionFromTileCoordinates(Tile);
		WorldData.GetFloorTilePositions(LocationVector, WorldData.WORLD_StepSize, 64 * 10, FloorPoints);

//		`LOG("[" $ GetFuncName() $ "] Floor Tiles: " $ FloorPoints.Length,,'WotC_Gameplay_SupportStrikes');
	}

	foreach FloorPoints(IterVector)
	{
		//AbilityContext.ResultContext.ProjectileHitLocations.AddItem(IterVector);
		
		// Ensure units that are in the tile are included in the damage results
		WorldData.GetFloorTileForPosition(IterVector, TempTile, false);
		UnitRefs = WorldData.GetUnitsOnTile(TempTile);
		foreach UnitRefs(UnitRef)
		{
			TileUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

			if (TileUnitState != none)
				MultiTargets.AdditionalTargets.AddItem(UnitRef);
		}

		// We already have done Units, try actors next (InteractiveLevelActor, DestructibleActor, etc.)
		TileActors = WorldData.GetActorsOnTile(TempTile, true);

		foreach TileActors(TileActor)
		{
			// Destructible and Interactive objects only!
			if ( TileActor.IsA('XComDestructibleActor') )
			{
				ObjRef = XComDestructibleActor(TileActor).GetState(none, false).GetReference();

				// Get the Reference and add it to the additional targets
				if (ObjRef.ObjectID > 0)
					MultiTargets.AdditionalTargets.AddItem(ObjRef);
			}
			else if ( TileActor.IsA('XComInteractiveLevelActor') )
			{
				ObjRef = XComInteractiveLevelActor(TileActor).GetState(none, false).GetReference();

				// Get the Reference and add it to the additional targets
				if (ObjRef.ObjectID > 0)
					MultiTargets.AdditionalTargets.AddItem(ObjRef);
			}
		}
		
		// Store the Tile information here
		AbilityContext.ResultContext.RelevantEffectTiles.AddItem(TempTile);
	}

//	`LOG("[" $ GetFuncName() $ "] New TargetLocation Size: " $ AbilityContext.InputContext.TargetLocations.Length,,'WotC_Gameplay_SupportStrikes');

	AbilityContext.InputContext.MultiTargets = MultiTargets.AdditionalTargets;
}

// Triggers the ability and kills the unit that owns this ability
static function XComGameState A10StrafingRun_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory 			History;	
	local XComGameState 				NewGameState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit 			UnitState;

	History = `XCOMHISTORY;	

	// Fire the ability as normal
	NewGameState = TypicalAbility_BuildGameState(Context);

	AbilityContext = XComGameStateContext_Ability(Context);

	// We need to kill the owner of this ability, the DummyTargetUnit. When they activate the 3rd Stage Angle ability, 
	// they become the source of this context when the 4th stage activates (this one).
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
	// Trigger the RemoveStateFromPlay function and event to properly remove this unit from the game
	if (UnitState.GetMyTemplateName() == 'Support_Strikes_Dummy_Target') 
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.RemoveStateFromPlay();
		`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', UnitState, UnitState, NewGameState);
	}

	return NewGameState;
}

// --------------------------------------------------------------------------------------
//
// Visualization Tree Setup:
// 1) Set up for visualization (Metadata, etc)
// 2) Roll and pick a random camera from the array of strings that stores our cameras
// 3) Create cinecamera and send it to our Cinescript Start Action. This is our Matinee.
// 4) Wait a few seconds before building the typical visualizer
// 5) Build typical visualizer (Our fire action that handles damage and env destruction
// 6) Build End Cinescript Action.
// 7) Restore the original value of the CinescriptCameraType from the ability template.
//
// --------------------------------------------------------------------------------------

simulated function A10StrafingRun_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory				History;
	local XComGameStateVisualizationMgr		VisualizationMgr;
	local XComGameStateContext_Ability		Context;
	local VisualizationActionMetadata		ActionMetadata, EmptyMetadata;
	local X2Action_Matinee_A10				MatineeAction;
	local X2Action_TimedWait				WaitAction;
	local X2Action							FoundAction;
	local vector							StartingPoint;
	local Rotator							NewRot;

	local int								iAlternateMatinee;


	//Build our typical fire action
	TypicalAbility_BuildVisualization(VisualizeGameState);

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Create metadata
	ActionMetadata = EmptyMetadata;
	History.GetCurrentAndPreviousGameStatesForObjectID(Context.InputContext.SourceObject.ObjectID,
													   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);	
	ActionMetadata.VisualizeActor = History.GetVisualizer(Context.InputContext.SourceObject.ObjectID);

	//Iridar: Find the Fire Action in vis tree configured by Typical Ability Build Viz
	FoundAction = VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_Fire');

    if (FoundAction != none)
    {
		//Roll for a random index
		iAlternateMatinee = `SYNC_RAND(A10_MatineeCommentPrefixes.Length);
		`LOG("[" $ GetFuncName() $ "] Picked " $ iAlternateMatinee $ " of " $ A10_MatineeCommentPrefixes.Length,,'WotC_Gameplay_SupportStrikes');

		//Perform Matinee on a separate branch
		MatineeAction = X2Action_Matinee_A10(class'X2Action_Matinee_A10'.static.AddToVisualizationTree(ActionMetadata, Context, false, FoundAction.ParentActions[0]));
	
		//Recalculate Rotator. Subtract the position of the final target location from the indicator unit to get the rotation
		StartingPoint = `XWORLD.GetPositionFromTileCoordinates(XComGameState_Unit(ActionMetadata.StateObject_NewState).TileLocation);

		NewRot = Rotator(Context.InputContext.TargetLocations[0] - StartingPoint);
		NewRot.Pitch = 0;
		NewRot.Roll = 0;

		MatineeAction.SetMatineeLocation(StartingPoint, NewRot);
		MatineeAction.MatineeCommentPrefix = default.A10_MatineeCommentPrefixes[iAlternateMatinee].Prefix;

		// Wait a few seconds before proceeding
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, Context, false, FoundAction.ParentActions[0]) );
		`LOG("[" $ GetFuncName() $ "] Delaying Fire Action by " $ default.A10_MatineeCommentPrefixes[iAlternateMatinee].FireTime $ " seconds!",,'WotC_Gameplay_SupportStrikes');
		WaitAction.DelayTimeSec = default.A10_MatineeCommentPrefixes[iAlternateMatinee].FireTime;

		VisualizationMgr.ConnectAction(FoundAction, VisualizationMgr.BuildVisTree, false, WaitAction);
	}
}

// Ability listener that activates the StrafingRun
static function EventListenerReturn StrafingRun_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit				SourceUnit;
	local ApplyEffectParametersObject		AEPObject;
	local XComGameState_Ability				SupportStrikeAbilityState;

	local AvailableAction                   Action;
	local array<vector>			            TargetLocs;

	SourceUnit 					= XComGameState_Unit(EventData);
	AEPObject 					= ApplyEffectParametersObject(EventSource);
	SupportStrikeAbilityState	= XComGameState_Ability(CallbackData);

	`LOG("SourceUnit: " $ SourceUnit.GetMyTemplateName() $ "\nAEP: " $ AEPObject $ "\nAbilityState: " $ SupportStrikeAbilityState.GetMyTemplateName() $ "\nOwner Matches? " $ SupportStrikeAbilityState.OwnerStateObject.ObjectID == SourceUnit.ObjectID, true, 'WotC_Gameplay_SupportStrikes');

	if (SourceUnit == none || AEPObject == none || SupportStrikeAbilityState == none)
    {
        return ELR_NoInterrupt;
    }

	// This must be the owner of this ability
	if (SupportStrikeAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		return ELR_NoInterrupt;
	}

	// Build our AvaliableAction instead of relying on the UnitCache
	Action.AbilityObjectRef = SupportStrikeAbilityState.GetReference();
	Action.AvailableCode = 'AA_Success';

	TargetLocs = AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations;

	//	Attempt to activate ability
	class'XComGameStateContext_Ability'.static.ActivateAbility(Action,, TargetLocs);

	return ELR_NoInterrupt;
}


// Special ability for the dummy target
// It's immune to everything, can't be hit, and has code required for removal.
static function X2AbilityTemplate CreateDummyTarget_Initialize()
{
	local X2AbilityTemplate			Template;
	local X2Effect_DummyTargetUnit	DummyImmunityEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DummyTargetIndicatorInitialize');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the immunities
	DummyImmunityEffect = new class'X2Effect_DummyTargetUnit';
	DummyImmunityEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin); // Last one is required to tick the effect proper
	Template.AddShooterEffect(DummyImmunityEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

defaultproperties
{
	StrafingRun_A10_Stage1_LocSelectEffectName	= "Effect_Support_Air_Off_StrafingRun_A10_Stage1"

	StrafingRun_A10_Stage2_FinalTriggerName		= "Trigger_Support_Air_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage3_FinalAbilityName		= "Ability_Support_Air_Off_StrafingRun_A10_Stage3_InitLocation"

	StrafingRun_A10_Stage3_EffectName			= "A10SupportStage3Effect";
	StrafingRun_A10_Stage4_FinalTriggerName		= "Trigger_Support_Air_Off_StrafingRun_A10_Stage4"
	StrafingRun_A10_Stage4_FinalAbilityName		= "Ability_Support_Air_Off_StrafingRun_A10_Stage4"
}