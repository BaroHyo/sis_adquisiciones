--------------- SQL ---------------

CREATE OR REPLACE FUNCTION adq.f_genera_preingreso_af_al (
  p_id_usuario integer,
  p_id_cotizacion integer,
  p_id_proceso_wf integer,
  p_id_estado_wf integer,
  p_codigo_ewf varchar,
  p_tipo_preingreso varchar
)
RETURNS boolean AS
$body$
/*
Autor: RCM
Fecha: 01/10/2013
Descripción: Generar el Preingreso a Activos Fijos

----------------------------------
Autor: 			RAC
Fecha:   		14/03/2014
Descripcion:  	Se generan id_proceso_wf independientes para almances y activos fijos



*/

DECLARE

	v_rec_cot record;
    v_rec_cot_det record;
    v_id_preingreso integer;
    v_id_proceso_wf integer;
    v_id_estado_wf integer;
    v_codigo_estado varchar;
    v_id_moneda	integer;
    v_resp boolean;
    v_precio_compra numeric;
    v_nombre_funcion varchar;
    v_estado_cuota varchar;
    v_id_depto integer;
    v_af integer;
    v_id_depto_conta integer;
    
    v_almacenable  varchar;
    v_activo_fijo  varchar;
    v_tipo   varchar;

BEGIN

	v_nombre_funcion='adq.f_genera_preingreso_af';
    v_af = 0;
    
    --inicia variable
    IF p_tipo_preingreso = 'preingreso_activo_fijo' THEN
    
      v_almacenable = 'no';
      v_activo_fijo = 'si';
      v_tipo = 'activo_fijo';
    
    ELSIF   p_tipo_preingreso = 'preingreso_almacen' THEN
    
      v_almacenable = 'si';
      v_activo_fijo = 'no';
      v_tipo = 'almacen';
    
    ELSE
    
       raise exception 'No se reconoce el tipo de preingreso';
    
    END IF;
  
    ---------------------
    --OBTENCION DE DATOS
    ---------------------
	--Cotización
    select 
       cot.id_cotizacion,
       cot.id_proceso_wf, 
       cot.id_estado_wf, 
       cot.estado, 
       cot.id_moneda,
       cot.id_obligacion_pago, 
       sol.justificacion, 
       cot.numero_oc
    into 
       v_rec_cot
    from adq.tcotizacion cot
    inner join adq.tproceso_compra pro on pro.id_proceso_compra = cot.id_proceso_compra
    inner join adq.tsolicitud sol on sol.id_solicitud = pro.id_solicitud
    where cot.id_cotizacion = p_id_cotizacion;
    
    --Moneda Base
    v_id_moneda = param.f_get_moneda_base();
    
    ---------------
    --VALIDACIONES
    ---------------
	--Existencia de la cotización en estado 'pago_habilitado'
	if v_rec_cot.id_cotizacion is null then
    	raise exception 'Cotización no encontrada';
    end if;
    
     if exists(select 1
              from alm.tpreingreso pi
              inner join  wf.tproceso_wf pwf on pwf.id_proceso_wf = pi.id_proceso_wf
              inner join wf.ttipo_proceso tp on tp.id_tipo_proceso = pwf.id_tipo_proceso
              where pi.id_cotizacion = p_id_cotizacion
              and  tp.codigo_llave = p_tipo_preingreso
              and estado in ('borrador','finalizado')) then
    	raise exception 'El Preingreso ya fue generado anteriormente.';
    end if;
	
     if exists(select 1
                  from adq.tcotizacion_det cdet
                  inner join adq.tsolicitud_det sdet
                  on sdet.id_solicitud_det = cdet.id_solicitud_det
                  inner join param.tconcepto_ingas cin
                  on cin.id_concepto_ingas = sdet.id_concepto_ingas
                  where cdet.id_cotizacion = p_id_cotizacion
                    and cdet.estado_reg = 'activo'
                    and cdet.cantidad_adju > 0
                    and lower(cin.tipo) = 'bien'
                    and lower(cin.activo_fijo) = v_activo_fijo 
                    and lower(cin.almacenable) = v_almacenable) then
        v_af = 1;
    end if;
    
   
    
    

    if  v_af = 0 then
    	raise exception 'La cotización no tiene ningún Activo Fijo. Nada que hacer.';
    end if;

	
    --------------------------
    -- CREACIÓN DE PREINGRESO
    --------------------------
    
    
    --Preingreso para Activos Fijos
    if v_af>0 then
    
           insert into alm.tpreingreso(
              id_usuario_reg, 
              fecha_reg, 
              estado_reg, 
              id_cotizacion,
              id_depto, 
              id_estado_wf, 
              id_proceso_wf, 
              estado, 
              id_moneda,
              tipo
            ) 
            values(
              p_id_usuario, 
              now(),
              'activo',
              p_id_cotizacion,
              null, 
              p_id_estado_wf, 
              p_id_proceso_wf, 
              p_codigo_ewf, 
              v_id_moneda,
              v_tipo
            ) returning id_preingreso into v_id_preingreso;
            
            
      

            --Generación del detalle del preingreso de activo fijo
            insert into alm.tpreingreso_det(
              id_usuario_reg, fecha_reg, estado_reg,
              id_preingreso, id_cotizacion_det, cantidad_det, precio_compra
            )
            select
              p_id_usuario, now(),'activo',        
              v_id_preingreso,cdet.id_cotizacion_det, cdet.cantidad_adju, cdet.precio_unitario_mb
            from adq.tcotizacion_det cdet
            inner join adq.tsolicitud_det sdet
            on sdet.id_solicitud_det = cdet.id_solicitud_det
            inner join param.tconcepto_ingas cin
            on cin.id_concepto_ingas = sdet.id_concepto_ingas
            where cdet.id_cotizacion = p_id_cotizacion
            and lower(cin.tipo) = 'bien'
            and lower(cin.activo_fijo) = v_activo_fijo
            and lower(cin.almacenable) = v_almacenable;
    end if;

    return true;
    
EXCEPTION
	WHEN OTHERS THEN
      v_resp='';
      v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
      v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
      v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
      raise exception '%',v_resp;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;