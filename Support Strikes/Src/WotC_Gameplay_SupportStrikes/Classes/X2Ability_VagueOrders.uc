class X2Ability_VagueOrders extends X2Ability
	config(GameData_SupportStrikes);

/// <summary>
/// Creates the set of abilities that implement vague orders
/// </summary>

// How this will work:
// * The XCom soldier will activate an ability (one of the Signal abilities below) which carries a specific Event Listener.
// * The resistance soldier on their turn will have the ability activated and do what's requested of them.
// NOTE: Some abilities are mutually exclusive to each other (i.e can't attack and suppress at the same time)


//
// LAYING THE FOUNDATION
// Sender_Radius
// Move: Orders the unit with this ability to move to a specified location
//
//
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_MovePassive' , 'Swarm_TriggerMovePassive', true));
	Templates.AddItem(CreateOrder_Move_Passive_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_MoveForced' , 'Swarm_TriggerMoveForce', true));
//	Templates.AddItem(CreateOrder_Move_Forced_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_Idle_HoldFire' , 'Swarm_TriggerIdleHoldFire'));
//	Templates.AddItem(CreateOrder_HoldFire_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_Idle_Defensive' , 'Swarm_TriggerIdleDefensive'));
//	Templates.AddItem(CreateOrder_Defensive_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_Idle_Aggressive' , 'Swarm_TriggerIdleAggressive'));
//	Templates.AddItem(CreateOrder_Aggressive_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_AttackTarget' , 'Swarm_TriggerAttackTarget', true));
//	Templates.AddItem(CreateOrder_AttackTarget_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_Signal_Swarm_Sender('Ability_Signal_Swarm_SuppressTarget' , 'Swarm_TriggerSuppressTarget', true));
//	Templates.AddItem(CreateOrder_SuppressTarget_Swarm_Receiver());

//	Templates.AddItem(CreateOrder_EscortAlly_Swarm_Receiver());

	// Necessary so that all allies will not be selectable
	Templates.AddItem(CreateAbility_Swarm_DrainAP());

	return Templates;
}

// --------------------------------------------------------------
// SIGNAL ABILITY
//
// --------------------------------------------------------------

//This is the first state of the mortar strike ability. It's purely to set up the strike with a timer before the next ability is triggered
static function X2DataTemplate CreateOrder_Signal_Swarm_Sender(name TemplateName, name TriggerEventName, optional bool bUseRadius = false)
{
	local X2AbilityTemplate							Template;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2AbilityMultiTarget_Radius				MultiTarget;
	local X2AbilityTarget_Cursor					CursorTarget;
	local X2Condition_Visibility					VisibilityCondition;
	local X2Condition_HeliDropIn					HeliDropInCheck;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_platform_stability"; // TODO: Change this icon
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;	//	visible while on cooldown
	Template.HideErrors.AddItem('AA_AbilityUnavailable');							//	but not visible if unavailable

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;

	//The weapon template has the actual amount of ammo
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	// Targeting properties, use Radius or Self
	if (bUseRadius)
	{
		//	Targeting and Triggering
		CursorTarget = new class'X2AbilityTarget_Cursor';
		//CursorTarget.bRestrictToSquadsightRange = true;
		Template.AbilityTargetStyle = CursorTarget;

		Template.TargetingMethod = class'X2TargetingMethod_VoidRift';

		MultiTarget = new class'X2AbilityMultiTarget_Radius';
		MultiTarget.fTargetRadius = 4.00f;
		MultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
		MultiTarget.bIgnoreBlockingCover = true;
		Template.AbilityMultiTargetStyle = MultiTarget;

		Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	}
	else
	{
		Template.AbilityToHitCalc = class'X2Ability'.default.DeadEye;

		Template.AbilityTargetStyle = default.SelfTarget;
		Template.AbilitySourceName = 'eAbilitySource_Standard';		
	}

	//	Ability Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//Just do the action while in cover
	Template.bSkipExitCoverWhenFiring = true;

	/* BEGIN Shooter Conditions */

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	//Prevent the ability from showing up if Vague Orders isn't enabled yet.
	HeliDropInCheck = new class'X2Condition_HeliDropIn';
	Template.AbilityShooterConditions.AddItem(HeliDropInCheck);

	/* END Shooter Conditions */

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bVisibleToAnyAlly = true;
	VisibilityCondition.bRequireLOS = false;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	return Template;
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

	// We need to enable Vague Orders on XCom's side now that heli reinforcements are in
	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	if (!SupportStrikeMgr.bEnableVagueOrders)
	{
		SupportStrikeMgr.bEnableVagueOrders = true;
		`LOG("[CallReinforcements_BuildGameState()] Vague Orders Enabled." ,,'WotC_Gameplay_SupportStrikes');
	}

	//Return the game state we have created
	return NewGameState;
}

// --------------------------------------------------------------
// RECEIVER ABILITIES
//
// --------------------------------------------------------------

static function X2AbilityTemplate CreateOrder_Move_Passive_Swarm_Receiver()
{
	local X2AbilityTemplate							Template;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2Effect_VagueOrder						OrderEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Receiver_Swarm_Move');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.AbilityToHitCalc = class'X2Ability'.default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

//	Template.AddShooterEffectExclusions();
//	Template.AbilityShooterConditions.AddItem(new class'X2Condition_Panic');
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	//Activate when the player triggers the Signal ability
//	ActivationTrigger = new class'X2AbilityTrigger_OnAbilityActivated';
//	ActivationTrigger.SetListenerData('Ability_Signal_Swarm_MovePassive');
//	Template.AbilityTriggers.AddItem(ActivationTrigger);

	OrderEffect = new class'X2Effect_VagueOrder';
	OrderEffect.EffectName	= 'Order_Swarm_Move';
	OrderEffect.Order		= '';
	OrderEffect.BuildPersistentEffect(1, , , , eGameRule_PlayerTurnEnd);  // infinite until the unit has reached the destination 

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function X2AbilityTemplate CreateAbility_Swarm_DrainAP()
{
	local X2AbilityTemplate							Template;
	local X2AbilityTrigger_OnAbilityActivated_Swarm	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Ability_Swarm_DrainAP');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Apply upon any ability activation.  This trigger checks for other requirements, i.e. unconcealed XCom action, exclusions.
	Trigger = new class'X2AbilityTrigger_OnAbilityActivated_Swarm';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.OnAbilityActivated;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.Priority = 20;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization; // Required for visualization of stun-removal.
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	Template.bSkipFireAction = true;
//	Template.bTickPerActionEffects = true;
//BEGIN AUTOGENERATED CODE: Template Overrides 'AlienRulerActionSystem'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'AlienRulerActionSystem'

	return Template;
}