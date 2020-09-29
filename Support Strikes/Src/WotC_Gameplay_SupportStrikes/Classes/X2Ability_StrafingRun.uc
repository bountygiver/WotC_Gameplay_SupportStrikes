class X2Ability_StrafingRun extends X2Ability_SupportStrikes_Common
	config(GameData_SupportStrikes);

var config int StrafingRun_A10_Local_Cooldown;				//
var config int StrafingRun_A10_Global_Cooldown;			//
var config int StrafingRun_A10_Delay_Turns;				// Number of turns before the next ability will fire
var config int StrafingRun_A10_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config bool StrafingRun_A10_Panic_Enable;
var config int StrafingRun_A10_Panic_NumOfTurns;

var config int StrafingRun_A10_TileWidth;
var config int StrafingRun_A10_Range;

var config bool StrafingRun_A10_Disorient_Enable;
var config int StrafingRun_A10_Disorient_NumOfTurns;

var config array<string> StrafingRun_A10_Stage2_AbilityCamera;

var name StrafingRun_A10_Stage1_DirSlcTriggerName;
var name StrafingRun_A10_Stage1_DirSlcAbilityName;
var name StrafingRun_A10_Stage1_LocSelectEffectName;

var name StrafingRun_A10_Stage2_FinalTriggerName;

var name StrafingRun_A10_Stage2_FinalAbilityName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage1());	//Primer
//	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage1_SelectAngle());	//The final confirmation ability

	Templates.AddItem(CreateSupport_Air_Offensive_StrafingRun_Stage2());

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
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_SpawnAOEIndicator			StrafingRun_A10_Stage1TargetEffect;
//	local X2AbilityCost_Ammo					AmmoCost;
	local X2Condition_MapCheck					MapCheck;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Air_Off_StrafingRun_A10_Stage1');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Always;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//The weapon template has the actual amount of ammo
	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Test
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal_All';
	Cooldown.iNumTurns = default.StrafingRun_A10_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.StrafingRun_A10_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	//Exclude dead units from using this ability
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Template.AbilityShooterConditions.AddItem(new class'X2Condition_ResourceCost');
	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	//  Spawn the spinny circle doodad
	StrafingRun_A10_Stage1TargetEffect = new class'X2Effect_SpawnAOEIndicator';
	StrafingRun_A10_Stage1TargetEffect.OverrideVFXPath = "XV_SupportStrike_ParticleSystems.ParticleSystems.A10_PrecisionStrike_Radial";
	Template.AddShooterEffect(StrafingRun_A10_Stage1TargetEffect);

	//Template.bSkipFireAction = true;

	Template.BuildNewGameStateFn = TypicalSupportStrike_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.AlternateFriendlyNameFn = TypicalSupportStrike_AlternateFriendlyName;

	return Template;
}

//The actual ability
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_Stage2()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		DelayedEventListener;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2AbilityMultiTarget_Radius			MultiTarget;
	//local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Line				LineMultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_PersistentStatChange			DisorientedEffect;
	local X2Effect_Panicked						PanickedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.StrafingRun_A10_Stage2_FinalAbilityName);
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.CinescriptCameraType = default.StrafingRun_A10_Stage2_AbilityCamera[0];

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

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

	Template.CinescriptCameraType = "MortarStrikeFinal";

	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.StrafingRun_A10_Stage2_FinalTriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = StrafingRun_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	//	Should not be here unless you want Mortars to stop firing if the soldier becomes disoriented or something like that.
	//Template.AddShooterEffectExclusions();

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

//
//	Template.bDontDisplayInAbilitySummary = true;
//	

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	//DamageEffect.EffectDamageValue = class'X2Item_SupportStrikes'.default.StrafingRun_A10_T1_BaseDamage;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
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

	Template.ActionFireClass = class'X2Action_Fire_StrafingRun_A10';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = A10StrafingRun_BuildVisualization;
	Template.BuildInterruptGameStateFn = None; // This ability cannot be interrupted

	Template.LostSpawnIncreasePerUse = default.StrafingRun_A10_LostSpawnIncreasePerUse;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
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
	local X2AbilityTemplate					AbilityTemplate;
	local VisualizationActionMetadata		ActionMetadata, SecondaryMetaData;
	local X2Action_Matinee_A10				MatineeAction;
	local X2Action_TimedWait				WaitAction;
	local X2Action_EndCinescriptCamera		CinescriptEndAction;
	local X2Action							FoundAction;
	local X2Action_MarkerNamed				JoinActions;
	local X2Action_Delay					DelayAction;
	local array<X2Action>					FoundActions;
	local Array<X2Action>					ParentActions;
	local Rotator							NewRot;
	local X2Action_WaitForAbilityEffect		WaitForFireEvent;

	local int								iAlternateMatinee;
	local string							PreviousCinescriptCameraType;


	//Build our typical fire action
	TypicalAbility_BuildVisualization(VisualizeGameState);

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Create metadatas
	ActionMetadata.StateObjectRef = Context.InputContext.SourceObject;
	ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObjectRef.ObjectID);
	History.GetCurrentAndPreviousGameStatesForObjectID(ActionMetadata.StateObjectRef.ObjectID,
													   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);	


	//Iridar: Find the Fire Action in vis tree configured by Typical Ability Build Viz
	FoundAction = VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_Fire');

    if (FoundAction != none)
    {
		//Roll for a random index
		iAlternateMatinee = `SYNC_RAND(A10_MatineeCommentPrefixes.Length);
		`LOG("[" $ GetFuncName() $ "] Picked " $ iAlternateMatinee $ " of " $ A10_MatineeCommentPrefixes.Length,,'WotC_Gameplay_SupportStrikes');


		//Perform Matinee on a separate branch
		MatineeAction = X2Action_Matinee_A10(class'X2Action_Matinee_A10'.static.AddToVisualizationTree(ActionMetadata, Context, false, FoundAction.ParentActions[0]));

		//Recalculate Rotator. We only want the Yaw
		NewRot = Rotator(Context.InputContext.TargetLocations[0]);
		NewRot.Pitch = 0;
		NewRot.Roll = 0;

		MatineeAction.SetMatineeLocation(Context.InputContext.TargetLocations[0], NewRot);
		MatineeAction.MatineeCommentPrefix = default.A10_MatineeCommentPrefixes[iAlternateMatinee].Prefix;

		// Wait a few seconds before proceeding
		WaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, Context, false, FoundAction.ParentActions[0]) );
		`LOG("[" $ GetFuncName() $ "] Delaying Fire Action by " $ default.A10_MatineeCommentPrefixes[iAlternateMatinee].FireTime $ " seconds!",,'WotC_Gameplay_SupportStrikes');
		WaitAction.DelayTimeSec = default.A10_MatineeCommentPrefixes[iAlternateMatinee].FireTime;

		VisualizationMgr.ConnectAction(FoundAction, VisualizationMgr.BuildVisTree, false, WaitAction);
	}


	// Join all 
	//VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, FoundActions);
	//
	////Visualization Fence. Wait for catchup
	////if (VisualizationMgr.BuildVisTree.ChildActions.Length > 0)
	////{
	////	JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, none, FoundActions));
	////	JoinActions.SetName("Join");
	////}
	//
	////Join again with the Typical Visualizer class
	//JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, none, FoundActions));
	//JoinActions.SetName("Join");
}

static function EventListenerReturn StrafingRun_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit				SourceUnit;
	//local XComGameState_Unit				OwnerUnit;
	local ApplyEffectParametersObject		AEPObject;
	local XComGameState_Ability				MortarAbilityState;
	local GameRulesCache_Unit				UnitCache;
	local int								i;
	//local UnitValue							UV;
	//local int								HistoryIndex;
	//local XComGameStateContext_Ability		AbilityContext;
	
	SourceUnit = XComGameState_Unit(EventData);
	AEPObject = ApplyEffectParametersObject(EventSource);
	MortarAbilityState = XComGameState_Ability(CallbackData);

	`LOG("Strafing Run Listener triggerred. SourceUnit unit: " @ SourceUnit.GetFullName() @ "AEPObject:" @ AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName @ AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] @ MortarAbilityState.GetMyTemplateName(),, 'IRIMORTAR');
	
	if (SourceUnit == none || AEPObject == none || MortarAbilityState == none)
    {
		`LOG("Strafing Run Listener: something wrong, exiting.",, 'IRIMORTAR');
        return ELR_NoInterrupt;
    }
	/*
	if (!SourceUnit.GetUnitValue('Support_Strike_Dummy_Target_SourceUnitID', UV))
	{
		`LOG("Strafing Run Listener: could not get Unit Value from spawned unit.",, 'IRIMORTAR');
        return ELR_NoInterrupt;
	}
	OwnerUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(MortarAbilityState.OwnerStateObject.ObjectID));
	if (OwnerUnit == none || MortarAbilityState.OwnerStateObject.ObjectID != UV.fValue)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Strafing Run Listener: ability doesn't belong to a unit that summoned this dummy target, or there is no owner unit (nani?!) exiting.",, 'IRIMORTAR');
		return ELR_NoInterrupt;
	}*/

	if (MortarAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Strafing Run Listener: ability belongs to another unit, exiting.",, 'IRIMORTAR');
		return ELR_NoInterrupt;
	}
	
	//HistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	if (`TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache))	//we get UnitCache for the soldier that triggered this event
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)	//then in all actions available to them
		{
			if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == MortarAbilityState.ObjectID)	//we find our Mortar Stage 2 ability
			{
				`LOG("Strafing Run Listener: found Stage 2 ability.",, 'IRIMORTAR');
				if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it succeeds all shooter conditions
				{
					// SPT_BeforeParallel - makes projectiles drop all at once, but bad viz
					if (class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],, AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations,,,, /*HistoryIndex*/,, /*SPT_BeforeParallel*/))
					{
						`LOG("Strafing Run Listener: fire in the hole!",, 'IRIMORTAR');
					}
					else
					{
						`LOG("Strafing Run Listener: could not activate ability.",, 'IRIMORTAR');
					}

					//Remove unit from game to free up resources
					`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', SourceUnit, SourceUnit, GameState);
				}
				else
				{
					`LOG("Strafing Run Listener: it cannot be activated currently!",, 'IRIMORTAR');
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

// Special ability for the dummy target
// It's immune to everything, can't be hit, and has code required for removal.
static function X2AbilityTemplate CreateDummyTarget_Initialize()
{
	local X2AbilityTemplate			Template;
	local X2Effect_DummyTargetUnit	DummyImmunityEffect;
	local X2Effect_UnblockPathing	CivilianUnblockPathingEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DummyTargetInitialize');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the immunities
	DummyImmunityEffect = new class'X2Effect_DummyTargetUnit';
	DummyImmunityEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Template.AddShooterEffect(DummyImmunityEffect);

	// Unblock effect
	CivilianUnblockPathingEffect = class'X2StatusEffects'.static.CreateCivilianUnblockedStatusEffect();
	Template.AddShooterEffect(CivilianUnblockPathingEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

defaultproperties
{
	StrafingRun_A10_Stage2_FinalAbilityName		= "Ability_Support_Air_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage2_FinalTriggerName		= "Trigger_Support_Air_Off_StrafingRun_A10_Stage2"
	StrafingRun_A10_Stage1_LocSelectEffectName	= "Effect_Support_Air_Off_StrafingRun_A10_Stage1"
}