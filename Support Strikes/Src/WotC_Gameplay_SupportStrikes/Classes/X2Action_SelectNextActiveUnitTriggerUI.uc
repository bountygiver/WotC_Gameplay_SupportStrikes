class X2Action_SelectNextActiveUnitTriggerUI extends X2Action_SelectNextActiveUnit;

var name AbilityName;

function CompleteAction()
{
	local int AbilityHudIndex;
	
    super.CompleteAction();

	// Force the tactical HUD to select the 0th ability
	AbilityHudIndex = `Pres.GetTacticalHUD().m_kAbilityHUD.GetAbilityIndexByName('Ability_Support_Air_Off_StrafingRun_Stage3_SelectAngle');
	if(AbilityHudIndex > -1)
	{
		`Pres.GetTacticalHUD().m_kAbilityHUD.SelectAbility( AbilityHudIndex );
	}
}

simulated state Executing
{
Begin:
	SelectTargetUnit();

	CompleteAction();
}