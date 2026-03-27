"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { eventSchema, type EventFormData } from "@bandz/shared/schemas";
import { Collections } from "@bandz/shared/constants";
import type { Artist } from "@bandz/shared/types";
import type { Place } from "@bandz/shared/types";
import { useCollection, useFirestoreMutations, generateDocId } from "@/lib/hooks/use-collection";
import { entityImageUrl, entityStoragePath } from "@/lib/legacy-image-url";
import { Card, CardContent } from "@/components/ui/card";
import { SectionHeader } from "@/components/section-header";
import { FormField } from "@/components/ui/form-field";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Combobox } from "@/components/ui/combobox";
import { StyleGroupSelect } from "@/components/ui/style-group-select";
import { StickyFormFooter } from "@/components/sticky-form-footer";
import { ImageUpload } from "@/components/image-upload";
import { Timestamp } from "firebase/firestore";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Youtube, ExternalLink } from "lucide-react";
import { DatePicker } from "@/components/ui/date-picker";
import { toast } from "sonner";
import { useUnsavedChanges } from "@/lib/hooks/use-unsaved-changes";

interface EventFormProps {
  initialData?: EventFormData & { id: string };
  id?: string;
}

export function EventForm({ initialData, id }: EventFormProps) {
  const router = useRouter();
  const { createWithId, update } = useFirestoreMutations(Collections.EVENTS);
  const [loading, setLoading] = useState(false);
  const isEditing = !!id;
  const entityId = useMemo(() => id || generateDocId(Collections.EVENTS), [id]);

  const { data: artists } = useCollection<Artist>(Collections.ARTISTS);
  const { data: places } = useCollection<Place>(Collections.PLACES);

  const artistOptions = artists.map((a) => ({ value: a.id, label: a.name }));
  const placeOptions = places.map((p) => ({ value: p.id, label: p.name }));

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    control,
    formState: { errors, isDirty },
  } = useForm<EventFormData>({
    resolver: zodResolver(eventSchema as any),
    defaultValues: initialData ?? {
      eventName: "",
      eventDate: (() => { const d = new Date(); d.setHours(21, 0, 0, 0); return d; })(),
      style: "",
      artistId: "",
      placeId: "",
      genres: [],
      styleGroupId: "",
      styleGroupName: "",
      styleGroupColor: "",
      styleGroupGenres: [],
      placeStyleGroupId: "",
      placeStyleGroupName: "",
      placeStyleGroupColor: "",
      placeStyleGroupGenres: [],
      description: "",
      youtubeURL: "",
      linkEvent: "",
      active: true,
      eventIsFree: false,
    },
  });

  useUnsavedChanges(isDirty);
  const activeValue = watch("active");
  const selectedArtistId = watch("artistId");
  const selectedPlaceId = watch("placeId");

  // Auto-inherit style group from selected artist
  useEffect(() => {
    if (selectedArtistId && !isEditing) {
      const artist = artists.find((a) => a.id === selectedArtistId);
      if (artist?.styleGroupId) {
        setValue("styleGroupId", artist.styleGroupId, { shouldValidate: true });
        setValue("styleGroupName", artist.styleGroupName ?? "", { shouldValidate: true });
        setValue("styleGroupColor", artist.styleGroupColor ?? "", { shouldValidate: true });
        setValue("styleGroupGenres", artist.styleGroupGenres ?? [], { shouldValidate: true });
      }
    }
  }, [selectedArtistId, artists, setValue, isEditing]);

  // Auto-inherit style group from selected place
  useEffect(() => {
    if (selectedPlaceId && !isEditing) {
      const place = places.find((p) => p.id === selectedPlaceId);
      if (place?.styleGroupId) {
        setValue("placeStyleGroupId", place.styleGroupId, { shouldValidate: true });
        setValue("placeStyleGroupName", place.styleGroupName ?? "", { shouldValidate: true });
        setValue("placeStyleGroupColor", place.styleGroupColor ?? "", { shouldValidate: true });
        setValue("placeStyleGroupGenres", place.styleGroupGenres ?? [], { shouldValidate: true });
      }
    }
  }, [selectedPlaceId, places, setValue, isEditing]);

  async function onSubmit(data: EventFormData) {
    setLoading(true);
    try {
      const selectedArtist = artists.find((a) => a.id === data.artistId);
      const selectedPlace = places.find((p) => p.id === data.placeId);

      const payload: Record<string, unknown> = { ...data };

      // Convert Date to Firestore Timestamp for storage
      if (data.eventDate) {
        payload.eventDate = Timestamp.fromDate(data.eventDate);
      }

      if (selectedArtist) {
        payload.artistName = selectedArtist.name;
        payload.artistStyleGroupId = selectedArtist.styleGroupId ?? null;
        payload.artistStyleGroupName = selectedArtist.styleGroupName ?? null;
        payload.artistStyleGroupGenres = selectedArtist.styleGroupGenres ?? null;
        payload.artistCity = selectedArtist.city ?? null;
        payload.artistState = selectedArtist.state ?? null;
        payload.artistCreatedAt = selectedArtist.createdDate ?? null;
      }
      if (selectedPlace) {
        payload.placeName = selectedPlace.name;
        payload.placeType = selectedPlace.placeType ?? "";
        payload.placeCity = selectedPlace.city ?? "";
        payload.placeState = selectedPlace.state ?? "";
        payload.placeCountry = selectedPlace.country ?? "";
        payload.placeGoogleRating = selectedPlace.googlePlaceRating ?? null;
        payload.placeGoogleTotalRatings = selectedPlace.googlePlaceUserRatingsTotal ?? null;
        payload.placeCreatedAt = selectedPlace.createdDate ?? null;
        payload.placeNeighborhood = selectedPlace.neighborhood ?? null;
        payload.placeOpeningHours = selectedPlace.googlePlaceOpeningHours?.weekday_text ?? null;
      }

      if (isEditing && id) {
        await update(id, payload);
        toast.success("Evento atualizado com sucesso");
      } else {
        await createWithId(entityId, payload);
        toast.success("Evento criado com sucesso");
      }
      router.push("/events");
    } catch {
      toast.error("Erro ao salvar evento");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="max-w-[800px] space-y-6 pb-24">
      {/* Evento */}
      <Card className="overflow-hidden">
        <SectionHeader icon="🎪" title="Evento" iconBg="bg-primary/10" />
        <CardContent className="p-5 space-y-5">
          <ImageUpload
            value={entityImageUrl("events", entityId)}
            onChange={() => {}}
            storagePath={entityStoragePath("events", entityId)}
            fixedPath
            label="Banner do Evento"
            aspectRatio="banner"
            className="mb-2"
          />
          <FormField label="Nome do Evento" required error={errors.eventName?.message}>
            <Input placeholder="Nome do evento" {...register("eventName")} />
          </FormField>

          <div className="grid gap-5 md:grid-cols-2">
            <FormField label="Estilo" error={errors.style?.message}>
              <Input placeholder="Ex: Show, Festival, DJ Set..." {...register("style")} />
            </FormField>

            <FormField label="Data do Evento" required error={errors.eventDate?.message}>
              <Controller
                name="eventDate"
                control={control}
                render={({ field }) => (
                  <DatePicker
                    value={field.value}
                    onChange={(d) => field.onChange(d)}
                    showTime
                  />
                )}
              />
            </FormField>
          </div>

          <div className="grid gap-5 md:grid-cols-2">
            <FormField label="Artista" required error={errors.artistId?.message}>
              <Controller
                name="artistId"
                control={control}
                render={({ field }) => (
                  <Combobox
                    options={artistOptions}
                    value={field.value}
                    onChange={field.onChange}
                    placeholder="Selecionar artista..."
                    searchPlaceholder="Buscar artista..."
                  />
                )}
              />
            </FormField>

            <FormField label="Casa" required error={errors.placeId?.message}>
              <Controller
                name="placeId"
                control={control}
                render={({ field }) => (
                  <Combobox
                    options={placeOptions}
                    value={field.value}
                    onChange={field.onChange}
                    placeholder="Selecionar casa..."
                    searchPlaceholder="Buscar casa..."
                  />
                )}
              />
            </FormField>
          </div>

          <div className="grid gap-5 md:grid-cols-2">
            <FormField label="Grupo de Estilo (Artista)" required error={errors.styleGroupId?.message}>
              <StyleGroupSelect
                value={watch("styleGroupId") ?? ""}
                onChange={(id, name, color, genres) => {
                  setValue("styleGroupId", id, { shouldValidate: true });
                  setValue("styleGroupName", name, { shouldValidate: true });
                  setValue("styleGroupColor", color, { shouldValidate: true });
                  setValue("styleGroupGenres", genres, { shouldValidate: true });
                }}
                error={errors.styleGroupId?.message}
              />
            </FormField>

            <FormField label="Grupo de Estilo (Casa)" required error={errors.placeStyleGroupId?.message}>
              <StyleGroupSelect
                value={watch("placeStyleGroupId") ?? ""}
                onChange={(id, name, color, genres) => {
                  setValue("placeStyleGroupId", id, { shouldValidate: true });
                  setValue("placeStyleGroupName", name, { shouldValidate: true });
                  setValue("placeStyleGroupColor", color, { shouldValidate: true });
                  setValue("placeStyleGroupGenres", genres, { shouldValidate: true });
                }}
                error={errors.placeStyleGroupId?.message}
              />
            </FormField>
          </div>

          <FormField label="Descrição" error={errors.description?.message}>
            <Textarea
              placeholder="Descrição do evento..."
              rows={3}
              {...register("description")}
            />
          </FormField>
        </CardContent>
      </Card>

      {/* Links */}
      <Card className="overflow-hidden">
        <SectionHeader icon="🔗" title="Links" iconBg="bg-blue-500/10" />
        <CardContent className="p-5 space-y-5">
          <div className="grid gap-5 md:grid-cols-2">
            <FormField label="YouTube URL" error={errors.youtubeURL?.message}>
              <div className="relative">
                <Youtube className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input placeholder="https://youtube.com/..." className="pl-10" {...register("youtubeURL")} />
              </div>
            </FormField>
            <FormField label="Link do Evento" error={errors.linkEvent?.message}>
              <div className="relative">
                <ExternalLink className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input placeholder="https://..." className="pl-10" {...register("linkEvent")} />
              </div>
            </FormField>
          </div>
        </CardContent>
      </Card>

      <StickyFormFooter
        onCancel={() => router.push("/events")}
        onSubmit={handleSubmit(onSubmit)}
        isActive={activeValue}
        onActiveChange={(val) => setValue("active", val, { shouldValidate: true })}
        submitLabel={isEditing ? "Salvar Alterações" : "Criar Evento"}
        loading={loading}
      >
        <div className="flex items-center gap-2">
          <Switch
            id="eventIsFree"
            checked={watch("eventIsFree") ?? false}
            onCheckedChange={(v) => setValue("eventIsFree", v, { shouldValidate: true })}
          />
          <Label htmlFor="eventIsFree" className="cursor-pointer text-sm text-muted-foreground">
            Evento Gratuito
          </Label>
        </div>
      </StickyFormFooter>
    </form>
  );
}
