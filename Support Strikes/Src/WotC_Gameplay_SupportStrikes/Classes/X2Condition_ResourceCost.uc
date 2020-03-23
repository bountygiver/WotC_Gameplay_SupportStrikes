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
	local XComGameState_HeadquartersXCom					XComHQ;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local int												Idx;
	local X2SoldierUnlockTemplate							UnlockTemplate;
	local X2StrategyElementTemplateManager					TemplateMan;
	local StrategyRequirement								NoRequirement;

	// TQL/Skirmish/Ladder/Challenge Mode does not have Strategy items
	if ( class'X2TacticalGameRulesetDataStructures'.static.TacticalOnlyGameMode(true) )
		return 'AA_Success';

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));

	Idx = SupportStrikeMgr.ScaledSupportStrikeCosts.Find('TemplateName', kAbility.GetMyTemplateName());
	if (Idx == INDEX_NONE)
		return 'AA_UnknownError';

	if ( !XComHQ.CanAffordAllStrategyCosts(SupportStrikeMgr.CurrentMonthAbilityIntelCost[Idx].StrikeCost, XComHQ.OTSUnlockScalars, XComHQ.GTSPercentDiscount) )
		return 'AA_NotEnoughResources_Intel';

	`LOG("[X2Condition_ResourceCost::CallMeetsCondition()] Condition Passed",class'X2DownloadableContentInfo_WotC_SupportStrikes'.static.Log(, true),'WotC_Gameplay_SupportStrikes');

	return 'AA_Success';
}