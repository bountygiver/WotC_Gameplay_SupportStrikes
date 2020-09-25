//---------------------------------------------------------------------------------------
// AUTHOR:	E3245
// DESC:	Checks current XCGS_BattleData and sees if a particular biome, plot, or parcel is loaded.
//			Fails if the current XCGS_BattleData contains any one of them.
//
//---------------------------------------------------------------------------------------

class X2Condition_ResourceCost extends X2Condition config (GameData);

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameStateHistory								History;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;

	// TQL/Skirmish/Ladder/Challenge Mode does not have Strategy items
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
		return 'AA_Success';

	History = `XCOMHISTORY;
	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	if (SupportStrikeMgr.EnoughIntelForStrike(kAbility.GetMyTemplateName()))
	{
//		`LOG("[X2Condition_ResourceCost::" $ GetFuncName() $ "] Condition Passed, Final Cost is " $ FinalCost, false,'WotC_Gameplay_SupportStrikes');
		return 'AA_Success';
	}
	
//	`LOG("[X2Condition_ResourceCost::" $ GetFuncName() $ "] Condition Failed, Final Cost is " $ FinalCost, false,'WotC_Gameplay_SupportStrikes');
	return 'AA_NotEnoughResources_Intel';
}