class X2Ability_SupportStrikes extends X2Ability
	config(GameData_SupportStrikes);

var config int MortarStrike_Local_Cooldown;				//
var config int MortarStrike_Global_Cooldown;			//
var config int MortarStrike_Delay_Turns;				// Number of turns before the next ability will fire
var config int MortarStrike_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config int MortarStrike_AdditionalSalvo_Turns;		// Number of turns that this ability will execute after the intial delay
var config float MortarStrike_Impact_Radius_Meters;
var config int MortarStrike_Environment_Damage_Amount;

var name MortarStrike_HE_Stage2AbilityName;
var name MortarStrike_HE_Stage2TriggerName;
var name BlazingPinionsStage1EffectName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
//	Templates.AddItem(CreateSupport_Air_Offensive_CarpetBombing());
//	Templates.AddItem(CreateSupport_Air_Offensive_PrecisionBombing());
//
//	Templates.AddItem(CreateSupport_Air_Offensive_PrecisionStrike());

	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1());
	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage2());

//	Templates.AddItem(CreateSupport_Artillery_Defensive_MortarStrike_SMK_Stage1());
//	Templates.AddItem(CreateSupport_Artillery_Defensive_MortarStrike_SMK_Stage2());

	return Templates;
}

//
// MORTAR STRIKE
//

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal		Cooldown;
	local X2AbilityMultiTarget_Cylinder			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Effect_DelayedAbilityActivation		DelayEffect_MortarStrike;
	local X2Condition_Visibility				VisibilityCondition;
	local int									idx;
	local int									AdditionalDelay;
	local name									EffectName;

//	local X2Effect_Persistent					BlazingPinionsStage1Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Land_Off_MortarStrike_HE_Stage1');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

//	Template.TwoTurnAttackAbility = default.MortarStrike_HE_Stage2AbilityName;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AddShooterEffectExclusions();

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.MortarStrike_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.MortarStrike_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Cursor';
	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	MultiTarget = new class'X2AbilityMultiTarget_Cylinder';
	MultiTarget.bUseOnlyGroundTiles = true;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
	MultiTarget.fTargetHeight = 10;
	Template.AbilityMultiTargetStyle = MultiTarget;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;

	AdditionalDelay = 0;
	//Delayed Effect to cause the second Mortar Strike stage to occur
	for (idx = 0; idx < (default.MortarStrike_AdditionalSalvo_Turns + 1); ++idx)
	{
		EffectName = name("MortarStrikeStage1Delay_" $ idx);
		AdditionalDelay += default.MortarStrike_Delay_Turns;

		DelayEffect_MortarStrike = new class 'X2Effect_DelayedAbilityActivation';
		DelayEffect_MortarStrike.BuildPersistentEffect(default.MortarStrike_Delay_Turns + idx, false, false, , eGameRule_PlayerTurnBegin);
		DelayEffect_MortarStrike.EffectName = EffectName;
		DelayEffect_MortarStrike.TriggerEventName = default.MortarStrike_HE_Stage2TriggerName;
		DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
		Template.AddShooterEffect(DelayEffect_MortarStrike);

		AdditionalDelay++;
	}

	// An effect to attach Perk FX to
//	BlazingPinionsStage1Effect = new class'X2Effect_Persistent';
//	BlazingPinionsStage1Effect.BuildPersistentEffect(1, true, false, true);
//	BlazingPinionsStage1Effect.EffectName = default.BlazingPinionsStage1EffectName;
//	Template.AddShooterEffect(BlazingPinionsStage1Effect);

	//  The target FX goes in target array as there will be no single target hit and no side effects of this touching a unit
//	Template.AddShooterEffect(new class'X2Effect_ApplyBlazingPinionsTargetToWorld');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
}

//The actual ability
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage2()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		DelayedEventListener;
//	local X2Effect_RemoveEffects				RemoveEffects;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
	local X2AbilityMultiTarget_Radius			RadMultiTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.MortarStrike_HE_Stage2AbilityName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.MortarStrike_HE_Stage2TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

//	RemoveEffects = new class'X2Effect_RemoveEffects';
//	RemoveEffects.EffectNamesToRemove.AddItem(default.BlazingPinionsStage1EffectName);
//	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_ApplyBlazingPinionsTargetToWorld'.default.EffectName);
//	Template.AddShooterEffect(RemoveEffects);

	RadMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadMultiTarget.fTargetRadius = default.MortarStrike_Impact_Radius_Meters;

	Template.AbilityMultiTargetStyle = RadMultiTarget;

	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = MortarStrikeStage2_BuildVisualization;
	Template.CinescriptCameraType = "Archon_BlazingPinions_Stage2";

	Template.LostSpawnIncreasePerUse = default.MortarStrike_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

simulated function MortarStrikeStage2_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack;
	local VisualizationActionMetadata ActionMetadata;
	local int i, j;
	local X2VisualizerInterface TargetVisualizerInterface;

	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local XComGameState_InteractiveObject InteractiveObject;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the source
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	// Play the firing action
	class'X2Action_MortarStrikeStageTwo'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

	for( i = 0; i < AbilityContext.ResultContext.ShooterEffectResults.Effects.Length; ++i )
	{
		AbilityContext.ResultContext.ShooterEffectResults.Effects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 
																								  AbilityContext.ResultContext.ShooterEffectResults.ApplyResults[i]);
	}

	if(AbilityContext.InputContext.MovementPaths.Length > 0)
	{
		class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, ActionMetadata);
	}
	

		//****************************************************************************************

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for (i = 0; i < AbilityContext.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = AbilityContext.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
		for( j = 0; j < AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, AbilityContext.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}

	//****************************************************************************************
	//Configure the visualization tracks for the environment
	//****************************************************************************************
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = none;
		ActionMetadata.StateObject_NewState = EnvironmentDamageEvent;
		ActionMetadata.StateObject_OldState = EnvironmentDamageEvent;

		//Wait until signaled by the shooter that the projectiles are hitting
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

		for( i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i )
		{
			AbilityTemplate.AbilityMultiTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');	
		}

			}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = none;
		ActionMetadata.StateObject_NewState = WorldDataUpdate;
		ActionMetadata.StateObject_OldState = WorldDataUpdate;

		//Wait until signaled by the shooter that the projectiles are hitting
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

		for( i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i )
		{
			AbilityTemplate.AbilityMultiTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');	
		}

			}
	//****************************************************************************************

	//Process any interactions with interactive objects
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		// Add any doors that need to listen for notification
		if( InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim() && InteractiveObject.InteractionCount % 2 != 0 ) //Is this a closed door?
		{
			ActionMetadata = EmptyTrack;
			//Don't necessarily have a previous state, so just use the one we know about
			ActionMetadata.StateObject_OldState = InteractiveObject;
			ActionMetadata.StateObject_NewState = InteractiveObject;
			ActionMetadata.VisualizeActor = History.GetVisualizer(InteractiveObject.ObjectID);
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);
			class'X2Action_BreakInteractActor'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);

					}
	}
}

defaultproperties
{
	MortarStrike_HE_Stage2AbilityName="Ability_Support_Land_Off_MortarStrike_HE_Stage2"
	MortarStrike_HE_Stage2TriggerName="Trigger_Support_Land_Off_MortarStrike_HE_Stage2"
	BlazingPinionsStage1EffectName="BlazingPinionsStage1Effect"
}