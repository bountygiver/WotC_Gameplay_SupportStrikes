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

var config int MortarStrike_SMK_Local_Cooldown;				//
var config int MortarStrike_SMK_Global_Cooldown;			//
var config int MortarStrike_SMK_Delay_Turns;				// Number of turns before the next ability will fire
var config int MortarStrike_SMK_LostSpawnIncreasePerUse;	// Increases the number of lost per usage
var config int MortarStrike_SMK_AdditionalSalvo_Turns;		// Number of turns that this ability will execute after the intial delay
var config int MortarStrike_SMK_Shells_Per_Turn;

var config int MortarStrike_SMK_InitialCharges;

var config int MortarStrike_SMK_HitMod;
var config int MortarStrike_SMK_AimMod;

enum eMortarEffect
{
	eME_Explosive,
	eME_Smoke,
	eME_Flash,
	eME_None
};


var name MortarStrike_Stage1_HE_EffectName;

var name MortarStrike_Stage2_HE_AbilityName;
var name MortarStrike_Stage2_HE_TriggerName;

var name MortarStrike_Stage2_SMK_AbilityName;
var name MortarStrike_Stage2_SMK_TriggerName;


var localized string MortarStrike_Stage2_SMK_EffectDisplayName;
var localized string MortarStrike_Stage2_SMK_EffectDisplayDesc;



static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1('Ability_Support_Land_Off_MortarStrike_HE_Stage1', eME_Explosive));
	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage2());

	Templates.AddItem(CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1('Ability_Support_Land_Def_MortarStrike_SMK_Stage1', eME_Smoke));
	Templates.AddItem(CreateSupport_Artillery_Defensive_MortarStrike_SMK_Stage2());

	return Templates;
}

//
// MORTAR STRIKE
//

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateSupport_Artillery_Offensive_MortarStrike_HE_Stage1(name TemplateName, eMortarEffect EffectCase)
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


	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

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


	switch (EffectCase)
	{
		case (eME_Explosive):
			Cooldown.iNumTurns = default.MortarStrike_HE_Local_Cooldown;
			Cooldown.NumGlobalTurns = default.MortarStrike_HE_Global_Cooldown;

			//Delayed Effect to cause the second Mortar Strike stage to occur
			for (idx = 0; idx < (default.MortarStrike_HE_AdditionalSalvo_Turns + 1); ++idx)
			{
				EffectName = name("MortarStrikeStage1Delay_" $ idx);

				DelayEffect_MortarStrike = new class 'X2Effect_IRI_DelayedAbilityActivation';
				DelayEffect_MortarStrike.BuildPersistentEffect(default.MortarStrike_HE_Delay_Turns + idx, false, false, false, eGameRule_PlayerTurnBegin);
				DelayEffect_MortarStrike.EffectName = EffectName;
				DelayEffect_MortarStrike.TriggerEventName = default.MortarStrike_Stage2_HE_TriggerName;
				DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
				Template.AddShooterEffect(DelayEffect_MortarStrike);
			}

			//  Spawn the spinny circle doodad
			Template.AddShooterEffect(new class'X2Effect_SpawnAOEIndicator');

			break;
		case (eME_Smoke):
			Cooldown.iNumTurns = default.MortarStrike_SMK_Local_Cooldown;
			Cooldown.NumGlobalTurns = default.MortarStrike_SMK_Global_Cooldown;

			//Delayed Effect to cause the second Mortar Strike stage to occur
			for (idx = 0; idx < (default.MortarStrike_SMK_AdditionalSalvo_Turns + 1); ++idx)
			{
				EffectName = name("MortarStrikeStage1Delay_" $ idx);

				DelayEffect_MortarStrike = new class 'X2Effect_IRI_DelayedAbilityActivation';
				DelayEffect_MortarStrike.BuildPersistentEffect(default.MortarStrike_SMK_Delay_Turns + idx, false, false, false, eGameRule_PlayerTurnBegin);
				DelayEffect_MortarStrike.EffectName = EffectName;
				DelayEffect_MortarStrike.TriggerEventName = default.MortarStrike_Stage2_SMK_TriggerName;
				DelayEffect_MortarStrike.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
				Template.AddShooterEffect(DelayEffect_MortarStrike);


			}

			//  Spawn the spinny circle doodad
			MortarStrike_HE_Stage1TargetEffect = new class'X2Effect_SpawnAOEIndicator';
			MortarStrike_HE_Stage1TargetEffect.OverrideVFXPath = "XV_SupportStrike_ParticleSystems.ParticleSystems.P_SupportStrike_AOE_Defensive";
			Template.AddShooterEffect(MortarStrike_HE_Stage1TargetEffect);

			break;
		default:
			break;
	}

	Template.AbilityCooldown = Cooldown;

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

	`CREATE_X2ABILITY_TEMPLATE(Template, default.MortarStrike_Stage2_HE_AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_bigbooms"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Never;

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


//
//	Template.bDontDisplayInAbilitySummary = true;
//	
	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.MortarStrike_Stage2_HE_TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = static.Mortar_Listener;
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

	Template.LostSpawnIncreasePerUse = default.MortarStrike_HE_LostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static function X2Effect SmokeMortarEffect()
{
	local X2Effect_SmokeMortar Effect;

	Effect = new class'X2Effect_SmokeMortar';
	//Must be at least as long as the duration of the smoke effect on the tiles. Will get "cut short" when the tile stops smoking or the unit moves. -btopp 2015-08-05
	Effect.BuildPersistentEffect(class'X2Effect_ApplySmokeMortarToWorld'.default.Duration + 1, false, false, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, default.MortarStrike_Stage2_SMK_EffectDisplayName, default.MortarStrike_Stage2_SMK_EffectDisplayDesc, "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke", true);
	Effect.HitMod = default.MortarStrike_SMK_HitMod;
	Effect.AimBonus = default.MortarStrike_SMK_AimMod;
	Effect.EffectTickedFn = SmokeEffectTicked;
	Effect.DuplicateResponse = eDupe_Refresh;
	return Effect;
}

function bool SmokeEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
    local XComGameState_Unit SourceUnit;

 
    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    if (SourceUnit != none)
		//Obviously, remove the effect if the Source Unit is not in the proper smoked tile
		if (!SourceUnit.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
			return true;

    return false; //  do not end the effect
}

//Smoke explosion ability
static function X2DataTemplate CreateSupport_Artillery_Defensive_MortarStrike_SMK_Stage2()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		DelayedEventListener;
	local X2Effect_RemoveEffects				RemoveEffects;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	/* Temp Shit */
	local X2AbilityMultiTarget_Radius			MultiTarget;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2Condition_UnitProperty				UnitPropertyCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.MortarStrike_Stage2_SMK_AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_bigbooms";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;

	//Conceal until the strike hits
	Template.ConcealmentRule = eConceal_Never;

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


//
//	Template.bDontDisplayInAbilitySummary = true;
//	
	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.MortarStrike_Stage2_SMK_TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_None;	//	other filters don't work with effect-triggered event.
	DelayedEventListener.ListenerData.EventFn = static.Mortar_Listener;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_SpawnAOEIndicator'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	// Damage and effects

	Template.AddMultiTargetEffect(new class'X2Effect_ApplySmokeMortarToWorld');
	//The actual smoke effect
	Template.AddMultiTargetEffect(SmokeMortarEffect());

	Template.ActionFireClass = class'X2Action_MortarStrikeStageTwo';
	Template.bSkipExitCoverWhenFiring = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Mortar_Stage2_BuildVisualization;

	Template.LostSpawnIncreasePerUse = default.MortarStrike_SMK_LostSpawnIncreasePerUse;
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

defaultproperties
{
	MortarStrike_Stage2_HE_AbilityName="Ability_Support_Land_Off_MortarStrike_HE_Stage2"
	MortarStrike_Stage2_HE_TriggerName="Trigger_Support_Land_Off_MortarStrike_HE_Stage2"
	MortarStrike_Stage2_SMK_AbilityName="Ability_Support_Land_Def_MortarStrike_SMK_Stage2"
	MortarStrike_Stage2_SMK_TriggerName="Trigger_Support_Land_Def_MortarStrike_SMK_Stage2"
	MortarStrike_Stage1_HE_EffectName="Effect_Support_Land_Off_MortarStrike_HE_Stage1"
}