<?php
/**
*@package pXP
*@file gen-SistemaDist.php
*@author  (fprudencio)
*@date 20-09-2011 10:22:05
*@description Archivo con la interfaz de usuario que permite la ejecucion de todas las funcionalidades del sistema
*/
header("content-type: text/javascript; charset=UTF-8");
?>
<script>
Phx.vista.PresolicitudCon = {
	require:'../../../sis_adquisiciones/vista/presolicitud/Presolicitud.php',
	requireclase:'Phx.vista.Presolicitud',
	title:'Presolicitud',
	nombreVista: 'PresolicitudCon',
	
	constructor: function(config) {
    	Phx.vista.PresolicitudCon.superclass.constructor.call(this,config);
    	this.addButton('apr_requerimiento',{text:'Finalizar',iconCls: 'badelante',disabled:true,handler:this.apr_requerimiento,tooltip: '<b>Aprobar </b><p>Aprobar el inicio de compra</p>'});
        this.iniciarEventos();
        this.init();
        this.store.baseParams={tipo_interfaz:this.nombreVista};
		this.load({params:{start:0, limit:this.tam_pag}});
		
		
	},
    apr_requerimiento:function()
        {                   
           var d= this.sm.getSelected().data;
           Phx.CP.loadingShow();
           Ext.Ajax.request({
               
                url:'../../sis_adquisiciones/control/Presolicitud/aprobarPresolicitud',
                params:{id_presolicitud:d.id_presolicitud,operacion:'finalizado'},
                success:this.successSinc,
                failure: this.conexionFailure,
                timeout:this.timeout,
                scope:this
            });     
     },
     successSinc:function(resp){
            
            Phx.CP.loadingHide();
            var reg = Ext.util.JSON.decode(Ext.util.Format.trim(resp.responseText));
            if(!reg.ROOT.error){
               
               this.reload();
                
            }else{
                alert('ocurrio un error durante el proceso')
            }
           
            
      },
    preparaMenu:function(n){
      var data = this.getSelectedData();
      var tb =this.tbar;
        Phx.vista.PresolicitudCon.superclass.preparaMenu.call(this,n);
        if(data.estado=='asignado'){
         this.getBoton('apr_requerimiento').enable();
        
        }
        else{
          this.getBoton('apr_requerimiento').disable();
        }
        this.getBoton('ant_estado').enable();
        this.getBoton('btnReporte').enable();  
         return tb 
     }, 
     liberaMenu:function(){
        var tb = Phx.vista.PresolicitudCon.superclass.liberaMenu.call(this);
        if(tb){
           
            this.getBoton('apr_requerimiento').disable();
            this.getBoton('ant_estado').disable(); 
            this.getBoton('btnReporte').disable();             
        }
       return tb
    },
    obtenerSolicitud:function(){
       return Phx.CP.getPagina(this.idContenedorPadre).obtenerSolicitud();   
    },	
    actualizarSolicitudDet:function(){
      
     Phx.CP.getPagina(this.idContenedorPadre).actualizarSolicitudDet();  
        
    },
    
	south:
          { 
          url:'../../../sis_adquisiciones/vista/presolicitud_det/PresolicitudConDet.php',
          title:'Detalle', 
          height:'50%',
          cls:'PresolicitudConDet'
         },
         bsave:false,
         bnew:false,
         bdel:false,
         bedit:false
};
</script>
