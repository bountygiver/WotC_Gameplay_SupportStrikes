//---------------------------------------------------------------------------------------
// FILE:	X2Ability_Recon.uc
// AUTHOR:	E3245
// DESC:	Ability that calls in a AWACS to perform reconnasiance. Depending on the tier, 
//			the ability can reveal hidden units, apply Target Definition (slow).
//
//---------------------------------------------------------------------------------------
class X2Ability_Recon extends X2Ability_SupportStrikes_Common
	config(GameData_SupportStrikes);

var config int		Recon_T1_Local_Cooldown;				//
var config int		Recon_T1_Global_Cooldown;			//
var config int		Recon_T1_Delay_Turns;				// Number of turns before the next ability will fire
var config int		Recon_T1_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config int		Recon_T1_NumberOfTurns;				// Number of turns that this ability will execute after the intial delay

var config float	Recon_T1_RingRadiusScale;
var config vector	Recon_T1_RingOffset;
var config string	Recon_T1_ParticleSystem;


var name Recon_T1_Stage2AbilityName;
var name Recon_T1_Stage2TriggerName;
var name Recon_T1_Stage1EffectName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupport_Airborne_Defensive_Recon_T1_Stage1());
	Templates.AddItem(CreateSupport_Airborne_Defensive_Recon_T1_Stage2());

	return Templates;
}

//
// Ion Cannon
//

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Airborne_Defensive_Recon_T1_Stage1()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal_All	Cooldown;
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Effect_IRI_DelayedAbilityActivation DelayEffect_MortarStrike;
	local X2Condition_Visibility				VisibilityCondition;
	local int									idx;
	local name									EffectName;
	local X2Effect_SpawnAOEIndicator			Recon_T1_Stage1TargetEffect;
	local X2AbilityCost_SharedCharges			AmmoCost;
	local X2Condition_MapCheck					MapCheck;
	local X2Condition_ResourceCost				IntelCostCheck;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Support_Airborne_Def_Recon_T1_Stage1');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_platform_stability"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal forever
	Template.ConcealmentRule = eConceal_Always;

	//The weapon template has the actual amount of ammo
	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	//Ammo Cost
	AmmoCost = new class'X2AbilityCost_SharedCharges';	
    AmmoCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	// Targeting Style/Method
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Self';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Ability Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal_All';
	Cooldown.iNumTurns = default.Recon_T1_Local_Cooldown;
	Cooldown.NumGlobalTurns = default.Recon_T1_Global_Cooldown;
	Template.AbilityCooldown = Cooldown;

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from executing if certain maps are loaded.
	MapCheck = new class'X2Condition_MapCheck';
	Template.AbilityShooterConditions.AddItem(MapCheck);

	IntelCostCheck = new class'X2Condition_ResourceCost';
	Template.AbilityShooterConditions.AddItem(IntelCostCheck);
	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);


	DelayEffect_MortarStrike = new class 'X2Effect_IRI_DelayedAbilityActivation';
	DelayEffect_MortarStrike.BuildPersistentEffect(default.Recon_T1_Delay_Turns, false, false, false, eGameRule_PlayerTurnBegin);
	DelayEffect_MortarStrike.EffectName = 'Recon_T1_Event';
	DelayEffect_MortarStrike.TriggerEventName = default.Recon_T1_Stage2TriggerName;
	DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayEffect_MortarStrike);

	//  Spawn the spinny circle doodad
//	Recon_T1_Stage1TargetEffect = new class'X2Effect_SpawnAOEIndicator';
//	Template.AddShooterEffect(Recon_T1_Stage1TargetEffect);

	Template.BuildNewGameStateFn = TypicalSupportStrike_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.AlternateFriendlyNameFn = TypicalSupportStrike_AlternateFriendlyName;

	return Template;
}

//The actual ability
static function X2DataTemplate CreateSupport_Airborne_Defensive_Recon_T1_Stage2()
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
	local X2AbilityMultiTarget_AllUnits			EnemyMultiTarget;
	local X2Effect_Recon						ReconEffect;
//	local X2Effect_Recon_TargetDef				ReconT2Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.Recon_T1_Stage2AbilityName);
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
//	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal forever
	Template.ConcealmentRule = eConceal_Always;
//
//	Template.bDontDisplayInAbilitySummary = true;
//	
	//	Targeting and Triggering
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SelfTarget;

	EnemyMultiTarget = new class'X2AbilityMultiTarget_AllUnits';
	EnemyMultiTarget.bAcceptEnemyUnits = true;
	Template.AbilityMultiTargetStyle = EnemyMultiTarget;

	Template.AbilityToHitCalc = default.DeadEye;
	
	//	Multi Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
    UnitPropertyCondition.ExcludeDead = true;
    UnitPropertyCondition.ExcludeFriendlyToSource = true;
    UnitPropertyCondition.ExcludeHostileToSource = false;
    UnitPropertyCondition.FailOnNonUnits = false;
	UnitPropertyCondition.ExcludeInStasis = false;
	UnitPropertyCondition.ExcludeUnrevealedAI = false;
    Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	//Template.CinescriptCameraType = "MortarStrikeFinal";

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Should not be here unless you want Mortars to stop firing if the soldier becomes disoriented or something like that.
	//Template.AddShooterEffectExclusions();

	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.Recon_T1_Stage2TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = Recon_T1_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

//	RemoveEffects = new class'X2Effect_RemoveEffects';
//	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
//	Template.AddShooterEffect(RemoveEffects);

	//Multitarget effects
	ReconEffect = new class'X2Effect_Recon';
	ReconEffect.BuildPersistentEffect(7, false, false, false, eGameRule_PlayerTurnEnd);	// Applies at the end of the enemies turn because we want to drop a PFX on the ground of where the unit is standing at
	ReconEffect.PFXScale =				default.Recon_T1_RingRadiusScale;
	ReconEffect.PFX =					default.Recon_T1_ParticleSystem;
	Template.AddMultiTargetEffect(ReconEffect);

//	ReconT2Effect = new class'X2Effect_Recon_TargetDef';
//	Template.AddMultiTargetEffect(ReconT2Effect);

//	Template.ActionFireClass = class'X2Action_Fire_Recon_T1';
	Template.bSkipFireAction = true;
	Template.bSkipExitCoverWhenFiring = true;

	//Skip visualization
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	// TODO: Build custom visualization
	Template.BuildInterruptGameStateFn = None; // This ability cannot be interrupted
//	Template.CinescriptCameraType = "Archon_BlazingPinions_Stage2";

//	Template.LostSpawnIncreasePerUse = default.Recon_T1_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AssociatedPlayTiming = SPT_AfterSequential;

	return Template;
}

//static function Recon_T1_Stage2_BuildVisualization(XComGameState VisualizeGameState)
//{
//	local XComGameStateVisualizationMgr		VisMgr;
//	local VisualizationActionMetadata		ActionMetadata;
//	local XComGameStateHistory				History;
//	local XComGameStateContext_Ability		Context;
//	local int								SourceUnitID;
//	local X2Action							FoundAction;
//	local X2Action_CameraLookAt				LookAtTargetAction;
//	local X2Action_PlaySoundAndFlyOver		SoundCueAction;
//	local X2Action_Delay					DelayAction;
//	local X2Action_PlayEffect				EffectAction;
//	local Object							SFX;
//
//	VisMgr = `XCOMVISUALIZATIONMGR;
//	History = `XCOMHISTORY;
//
//	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());	
//
//	ActionMetadata.StateObjectRef = Context.InputContext.SourceObject;
//	ActionMetadata.VisualizeActor = History.GetVisualizer(ActionMetadata.StateObjectRef.ObjectID);
//	History.GetCurrentAndPreviousGameStatesForObjectID(ActionMetadata.StateObjectRef.ObjectID,
//													   ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,
//													   eReturnType_Reference,
//													   VisualizeGameState.HistoryIndex);	
//
//	//Play the suck up effect before the typical viz is created
//	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context));
//	EffectAction.EffectName = "FX_RenX_Recon_T1Strike.ParticleSystems.P_GroundUpSuck";
//	EffectAction.EffectLocation = Context.InputContext.TargetLocations[0];
//	EffectAction.bWaitForCompletion = false;
//
//	//Preload SFX, if it fails don't play
//	SFX = `CONTENT.RequestGameArchetype("FX_RenX_Recon_T1Strike.SoundCues.Recon_T1_BuildUp");
//
//	if (SFX != none && SFX.IsA('SoundCue'))
//	{
//		SoundCueAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//		SoundCueAction.SetSoundAndFlyOverParameters(SoundCue(SFX), "", '', eColor_Good);
//	}
//
//	// Pan camera towards target location
//	// NOTE: Look at is here to focus on the pretty particle effect BEFORE the projectile is fired
//    LookAtTargetAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//	LookAtTargetAction.LookAtLocation = Context.InputContext.TargetLocations[0];
//	LookAtTargetAction.LookAtDuration = 13.00f;
//	LookAtTargetAction.SnapToFloor = false;
//	LookAtTargetAction.TargetZoomAfterArrival = 1.00f;
//	
//	//Delay the Beam effect until this time
//	DelayAction = X2Action_Delay( class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//	DelayAction.Duration = 6.50f;
//
//	//Play the beam effect
//	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//	EffectAction.EffectName = "FX_RenX_Recon_T1Strike.ParticleSystems.P_Beam";
//	EffectAction.EffectLocation = Context.InputContext.TargetLocations[0];
//	EffectAction.bWaitForCompletion = false;
//
//	//Prevent the fire action from playing until this amount of time as passed
//	DelayAction = X2Action_Delay( class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//	DelayAction.Duration = 2.00f;
//
//	//Iridar: Call the typical ability visuailzation. With just that, the ability would look like the soldier firing the rocket upwards, and then enemy getting damage for seemingly no reason.
//	class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);
//
//	//Gather information about our created visualizer
//	SourceUnitID = ActionMetadata.StateObjectRef.ObjectID;
//	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnitID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
//	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(SourceUnitID);
//
//	//Iridar: Find the Fire Action in vis tree configured by Typical Ability Build Viz
//	FoundAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_Fire');
//
//    if (FoundAction != none)
//    {
//		DelayAction = X2Action_Delay( class'X2Action_Delay'.static.AddToVisualizationTree( ActionMetadata, Context, false, ActionMetadata.LastActionAdded) );
//		DelayAction.Duration = 2.00f;
//
//		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
//		EffectAction.EffectName = "FX_RenX_Recon_T1Strike.ParticleSystems.P_AftermathClouds";
//		EffectAction.EffectLocation = Context.InputContext.TargetLocations[0];
//		EffectAction.bWaitForCompletion = false;
//	}
//}

static function EventListenerReturn Recon_T1_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
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

	`LOG("Ion Cannon triggerred. SourceUnit unit: " @ SourceUnit.GetFullName() @ "AEPObject:" @ AEPObject.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName @ AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations[0] @ MortarAbilityState.GetMyTemplateName(),, 'IRIMORTAR');
	
	if (SourceUnit == none || AEPObject == none || MortarAbilityState == none)
    {
		`LOG("Ion Cannon: something wrong, exiting.",, 'IRIMORTAR');
        return ELR_NoInterrupt;
    }
	if (MortarAbilityState.OwnerStateObject.ObjectID != SourceUnit.ObjectID)
	{
		//	Can happen if multiple soldiers carry Mortar Strike calldown weapon.
		`LOG("Ion Cannon: ability belongs to another unit, exiting.",, 'IRIMORTAR');
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
					`LOG("Ion Cannon: found Stage 2 ability.",, 'IRIMORTAR');
					if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it succeeds all shooter conditions
					{
						// SPT_BeforeParallel - makes projectiles drop all at once, but bad viz
						if (class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],, AEPObject.ApplyEffectParameters.AbilityInputContext.TargetLocations,,,, /*HistoryIndex*/,, /*SPT_BeforeParallel*/))
						{
							`LOG("Ion Cannon: fire in the hole!",, 'IRIMORTAR');
						}
						else
						{
							`LOG("Ion Cannon: could not activate ability.",, 'IRIMORTAR');
						}
					}
					else
					{
						`LOG("Ion Cannon: it cannot be activated currently!",, 'IRIMORTAR');
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

defaultproperties
{
	Recon_T1_Stage2AbilityName="Ability_Support_Airborne_Def_Recon_T1_Stage2"
	Recon_T1_Stage2TriggerName="Trigger_Support_Airborne_Def_Recon_T1_Stage2"
	Recon_T1_Stage1EffectName="Effect_Support_Airborne_Def_Recon_T1_Stage1"
}