class X2Ability_MortarStrikes extends X2Ability
	config(GameData_SupportStrikes);

var config int MortarStrike_HE_Local_Cooldown;				//
var config int MortarStrike_HE_Global_Cooldown;			//
var config int MortarStrike_HE_Delay_Turns;				// Number of turns before the next ability will fire
var config int MortarStrike_HE_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config int MortarStrike_HE_AdditionalSalvo_Turns;		// Number of turns that this ability will execute after the intial delay
var config int MortarStrike_HE_Shells_Per_Turn;
var config bool MortarStrike_HE_Panic_Enable;
var config int MortarStrike_HE_Panic_NumOfTurns;

var config bool MortarStrike_HE_Disorient_Enable;
var config int MortarStrike_HE_Disorient_NumOfTurns;

//VFXs
//var config string MortarStrike_HE_TargetVFX_Path;

var name MortarStrike_HE_Stage2AbilityName;
var name MortarStrike_HE_Stage2TriggerName;
var name MortarStrike_HE_Stage1EffectName;



static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
//	Templates.AddItem(CreateSupport_Air_Offensive_CarpetBombing());
//	Templates.AddItem(CreateSupport_Air_Offensive_PrecisionBombing());
//
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
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Effect_IRI_DelayedAbilityActivation DelayEffect_MortarStrike;
	local X2Condition_Visibility				VisibilityCondition;
	local int									idx;
	local name									EffectName;
	local X2Effect_SpawnAOEIndicator			MortarStrike_HE_Stage1TargetEffect;
	local X2AbilityCost_SharedCharges			AmmoCost;
	local X2Condition_MapCheck					MapCheck;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Land_Off_MortarStrike_HE_Stage1');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//The weapon template has the actual amount of ammo
	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Ammo Cost
	AmmoCost = new class'X2AbilityCost_SharedCharges';	
	Template.AbilityCosts.AddItem(AmmoCost);

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Ability Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.MortarStrike_HE_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.MortarStrike_HE_Global_Cooldown;
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

	//Delayed Effect to cause the second Mortar Strike stage to occur
	for (idx = 0; idx < (default.MortarStrike_HE_AdditionalSalvo_Turns + 1); ++idx)
	{
		EffectName = name("MortarStrikeStage1Delay_" $ idx);

		DelayEffect_MortarStrike = new class 'X2Effect_IRI_DelayedAbilityActivation';
		DelayEffect_MortarStrike.BuildPersistentEffect(default.MortarStrike_HE_Delay_Turns + idx, false, false, false, eGameRule_PlayerTurnBegin);
		DelayEffect_MortarStrike.EffectName = EffectName;
		DelayEffect_MortarStrike.TriggerEventName = default.MortarStrike_HE_Stage2TriggerName;
		DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
		Template.AddShooterEffect(DelayEffect_MortarStrike);

	}

	//  Spawn the spinny circle doodad
	MortarStrike_HE_Stage1TargetEffect = new class'X2Effect_SpawnAOEIndicator';
	Template.AddShooterEffect(MortarStrike_HE_Stage1TargetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
}

//The actual ability
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage2()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		DelayedEventListener;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2Effect_ApplyWeaponDamage			DamageEffect;
//	local X2AbilityMultiTarget_Radius			RadMultiTarget;
	//local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
//	local X2Condition_Visibility				VisibilityCondition;
	local X2Condition_UnitProperty				UnitPropertyCondition;
	local X2Effect_PersistentStatChange			DisorientedEffect;
	local X2Effect_Panicked						PanickedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.MortarStrike_HE_Stage2AbilityName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	//	Targeting and Triggering
	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.bUseWeaponRadius = true;
//	MultiTarget.fTargetHeight = 10;
	Template.AbilityMultiTargetStyle = MultiTarget;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;	//	E3245 - up to you if you want this to crit or not.
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

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Should not be here unless you want Mortars to stop firing if the soldier becomes disoriented or something like that.
	//Template.AddShooterEffectExclusions();

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;
//
//	Template.bDontDisplayInAbilitySummary = true;
//	
	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.MortarStrike_HE_Stage2TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = Mortar_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects
	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bExplosiveDamage = true;
	DamageEffect.bIgnoreBaseDamage = false;
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	if (default.MortarStrike_HE_Panic_Enable)
	{

		//  Panic effect
		PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
		PanickedEffect.iNumTurns = default.MortarStrike_HE_Panic_NumOfTurns;
		PanickedEffect.MinStatContestResult = 2;
		PanickedEffect.MaxStatContestResult = 3;
		Template.AddTargetEffect(PanickedEffect);

	}

	if (default.MortarStrike_HE_Disorient_Enable)
	{
		//  Disorient effect
		DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
		DisorientedEffect.iNumTurns = default.MortarStrike_HE_Disorient_NumOfTurns;
		DisorientedEffect.MinStatContestResult = 1;
		DisorientedEffect.MaxStatContestResult = 1;
		Template.AddTargetEffect(DisorientedEffect);
	}

	Template.ActionFireClass = class'X2Action_MortarStrikeStageTwo';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Mortar_Stage2_BuildVisualization;
	//Template.MergeVisualizationFn = Mortar_Stage2_MergeVisualization;
//	Template.CinescriptCameraType = "Archon_BlazingPinions_Stage2";

	Template.LostSpawnIncreasePerUse = default.MortarStrike_HE_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static function Mortar_Stage2_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local VisualizationActionMetadata		ActionMetadata;
	local XComGameStateHistory				History;
	local XComGameStateContext_Ability		Context;
	local int								SourceUnitID;
	local X2Action							FoundAction;
	local X2Action_CameraLookAt				LookAtTargetAction;

	//Iridar: Call the typical ability visuailzation. With just that, the ability would look like the soldier firing the rocket upwards, and then enemy getting damage for seemingly no reason.
	class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	SourceUnitID = Context.InputContext.SourceObject.ObjectID;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnitID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(SourceUnitID);

	//Iridar: Find the Fire Action in vis tree configured by Typical Ability Build Viz
	FoundAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_Fire');

    if (FoundAction != none)
    {
        //    Add a camera action as a child to the Fire Action's parent, that lets both Fire Action and Camera Action run in parallel
        //    pan camera towards the shooter for the firing animation
        LookAtTargetAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, FoundAction.ParentActions[0]));
		LookAtTargetAction.LookAtLocation = Context.InputContext.TargetLocations[0];
		LookAtTargetAction.LookAtDuration = 2.00f;
	}
}


static function Mortar_Stage2_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local array<X2Action>					FindActions;
	local X2Action							FindAction;
	local X2Action_TimedWait				TimedWait;
	local X2Action							DesiredParent;
	local XComGameStateContext_Ability		Context;	
	local VisualizationActionMetadata		ActionMetadata;
	local X2Action_MarkerNamed				MarkerNamed;
	local float								PreviousDelay;
	local float								FoundDelay;

	`LOG("Mortar Merge: running.",, 'IRIMORTARVIZ');

	VisMgr = `XCOMVISUALIZATIONMGR;	
	Context = XComGameStateContext_Ability(BuildTree.StateChangeContext);
	
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerTreeInsertBegin', FindActions);
	`LOG("Mortar Merge: found marker tree insert actions: " @ FindActions.Length @ "desired index:" @ Context.DesiredVisualizationBlockIndex,, 'IRIMORTARVIZ');

	DesiredParent = FindActionWithClosestHistoryIndex(FindActions, Context.DesiredVisualizationBlockIndex);

	if (DesiredParent == none) 
	{
		`LOG("Mortar Merge: could not find even one desired parent, doing failsafe.",, 'IRIMORTARVIZ');
		XComGameStateContext_Ability(BuildTree.StateChangeContext).SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
	}
	else
	{
		//	Each Mortar Strike has a delay before it is visualized, we store that delay in MarkerNamed actions so that 
		//	we can space them out as we want.
		//	This will find the longest delay before any of the Mortar Strikes that have already ran their Merge Vis functions.
		VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerNamed', FindActions);
		foreach FindActions(FindAction)
		{
			MarkerNamed = X2Action_MarkerNamed(FindAction);
			if (InStr(MarkerNamed.MarkerName, "E3245_Mortar_Strike_") != INDEX_NONE)
			{
				FoundDelay = float(Mid(MarkerNamed.MarkerName, 20));

				if (FoundDelay > PreviousDelay) PreviousDelay = FoundDelay;
			}
		}
		`LOG("Mortar Merge: delay from previous Mortar Strike:" @ MarkerNamed.MarkerName @ PreviousDelay,, 'IRIMORTARVIZ');
			
		ActionMetadata = DesiredParent.Metadata;
		TimedWait = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, DesiredParent.StateChangeContext, false, DesiredParent));

		//	If this Mortar Strike is not first in the salvo, then make sure there's at least half a second delay before strikes
		if (PreviousDelay != 0) PreviousDelay += 0.5f;

		//	Add a random delay before this particular mortar strike is visualized
		PreviousDelay += `SYNC_FRAND_STATIC() * 0.75f;	//	0.0 - 0.75 sec random delay			
				 
		TimedWait.DelayTimeSec = PreviousDelay;

		MarkerNamed = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, DesiredParent.StateChangeContext, false, TimedWait));
		MarkerNamed.SetName("E3245_Mortar_Strike_" $ PreviousDelay);

		`LOG("Mortar Merge: all fine, new delay:" @ MarkerNamed.MarkerName @ PreviousDelay,, 'IRIMORTARVIZ');

		VisMgr.ConnectAction(BuildTree, VisualizationTree, false, MarkerNamed);
	}
}

static function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;

	`LOG("Action layer: " @ iLayer @ ": " @ Action.Class.Name @ Action.StateChangeContext.AssociatedState.HistoryIndex,, 'VIZPRINTOUT'); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}

static function X2Action FindActionWithClosestHistoryIndex(const array<X2Action> FindActions, const int DesiredHistoryIndex)
{
	local X2Action FindAction;
	local X2Action BestAction;
	local int	   HistoryIndexDelta;

	if (FindActions.Length == 1)
		return FindActions[0];

	foreach FindActions(FindAction)
	{
		if (FindAction.StateChangeContext.AssociatedState.HistoryIndex == DesiredHistoryIndex)
		{
			return FindAction;
		}
		//	This Fire Action is older
		//	and the difference in History Indices is smaller than for the Action that we have found previously.
		if (FindAction.StateChangeContext.AssociatedState.HistoryIndex < DesiredHistoryIndex &&
		HistoryIndexDelta > DesiredHistoryIndex - FindAction.StateChangeContext.AssociatedState.HistoryIndex)
		{	
			HistoryIndexDelta = DesiredHistoryIndex - FindAction.StateChangeContext.AssociatedState.HistoryIndex;
			BestAction = FindAction;

			//	No break on purpose! We want the cycle to sift through all Fire Actions in the tree.
		}
	}
	return BestAction;
}

static function EventListenerReturn Mortar_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit				SourceUnit;
	local ApplyEffectParametersObject		AEPObject;
	local XComGameState_Ability				MortarAbilityState;
	local GameRulesCache_Unit				UnitCache;
	local int								i, j;
	//local int								HistoryIndex;
	//local XComGameStateContext_Ability		AbilityContext;
	
	SourceUnit = XComGameState_Unit(EventData);
	AEPObject = ApplyEffectParametersObject(EventSource);
	MortarAbilityState = XComGameState_Ability(CallbackData);

	`LOG("Mortar Listener triggerred. SourceUnit unit: " @ SourceUnit.GetFullName() @ "AEPObject:" @ AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName @ AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] @ MortarAbilityState.GetMyTemplateName(),, 'IRIMORTAR');
	
	if (SourceUnit == none || AEPObject == none || MortarAbilityState == none)
    {
		`LOG("Mortar Listener: something wrong, exiting.",, 'IRIMORTAR');
        return ELR_NoInterrupt;
    }
	if (MortarAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Mortar Listener: ability belongs to another unit, exiting.",, 'IRIMORTAR');
		return ELR_NoInterrupt;
	}
	//HistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	//	Attempt to activate ability this many times
	for (j = 0; j < default.MortarStrike_HE_Shells_Per_Turn; j++)
	{
		if (`TACTICALRULES.GetGameRulesCache_Unit(SourceUnit.GetReference(), UnitCache))	//we get UnitCache for the soldier that triggered this event
		{
			for (i = 0; i < UnitCache.AvailableActions.Length; ++i)	//then in all actions available to them
			{
				if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == MortarAbilityState.ObjectID)	//we find our Mortar Stage 2 ability
				{
					`LOG("Mortar Listener: found Stage 2 ability.",, 'IRIMORTAR');
					if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it succeeds all shooter conditions
					{
						// SPT_BeforeParallel - makes projectiles drop all at once, but bad viz
						if (class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],, AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations,,,, /*HistoryIndex*/,, /*SPT_BeforeParallel*/))
						{
							`LOG("Mortar Listener: fire in the hole!",, 'IRIMORTAR');
						}
						else
						{
							`LOG("Mortar Listener: could not activate ability.",, 'IRIMORTAR');
						}
					}
					else
					{
						`LOG("Mortar Listener: it cannot be activated currently!",, 'IRIMORTAR');
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
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
	MortarStrike_HE_Stage1EffectName="Effect_Support_Land_Off_MortarStrike_HE_Stage1"
}