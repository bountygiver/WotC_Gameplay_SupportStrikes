//---------------------------------------------------------------------------------------
// AUTHOR:	E3245
// DESC:	Specific Heli Drop in conditions. 
//			Firstly, the GTS perk or whatever must have been bought.
//
//---------------------------------------------------------------------------------------
class X2Condition_HeliDropIn extends X2Condition config (GameData);

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	if (SupportStrikeMgr == none)
		return 'AA_UnknownError';

	if (!SupportStrikeMgr.bHeliDropInCalled)
		return 'AA_AbilityUnavailable';

	return 'AA_Success';
}