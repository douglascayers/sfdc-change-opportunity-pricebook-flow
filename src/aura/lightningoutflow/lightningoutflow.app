<aura:application access="global" extends="ltng:outApp" >
    <aura:dependency resource="lightning:flow"/>
    <lightning:flow aura:id="flowData" onstatuschange="{!c.handleStatusChange}" />
</aura:application>